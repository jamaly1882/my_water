/* ============================================================
   voice_translate.js — جسر الصوت بين المتصفح و Flutter
   ------------------------------------------------------------
   1) الميكروفون : Web Speech API (Chrome) → تفريغ إنجليزي فوري
                   بلا خادم وبلا تكلفة.
   2) صوت الاجتماع: getDisplayMedia(audio) + MediaRecorder
                   → بثّ مقاطع إلى خدمة تفريغ عبر WebSocket
                   (Whisper ونحوه). يحتاج خادماً مهيأً.
   الترجمة إلى العربية لا تتم هنا بل في Dart عبر /api/translate/
   ============================================================ */

(function () {
  'use strict';

  var state = {
    recognition: null,
    listening: false,
    lang: 'en-US',
    onText: null,
    onStatus: null,
    onError: null,
    captureStream: null,
    recorder: null,
    socket: null,
    wsUrl: ''
  };

  function status(message) {
    if (state.onStatus) state.onStatus(String(message));
  }

  function fail(message) {
    if (state.onError) state.onError(String(message));
  }

  function emit(text, isFinal) {
    if (state.onText) state.onText(String(text || ''), !!isFinal);
  }

  function hasSpeech() {
    return !!(window.SpeechRecognition || window.webkitSpeechRecognition);
  }

  /* ----------------------------------------------------------
     الميكروفون — تعرّف فوري في المتصفح
     ---------------------------------------------------------- */

  function startMic(lang, onText, onStatus, onError) {
    state.onText = onText;
    state.onStatus = onStatus;
    state.onError = onError;
    state.lang = lang || 'en-US';

    if (!hasSpeech()) {
      fail('هذا المتصفح لا يدعم التعرّف على الكلام. استخدم Chrome أو Edge.');
      return;
    }

    var Ctor = window.SpeechRecognition || window.webkitSpeechRecognition;
    var recognition = new Ctor();

    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.maxAlternatives = 1;
    recognition.lang = state.lang;

    recognition.onstart = function () {
      status('يستمع إلى الميكروفون…');
    };

    recognition.onresult = function (event) {
      var interim = '';

      for (var i = event.resultIndex; i < event.results.length; i++) {
        var result = event.results[i];
        var alternative = result[0];

        if (!alternative) continue;

        if (result.isFinal) {
          emit(alternative.transcript, true);
        } else {
          interim += alternative.transcript;
        }
      }

      if (interim) emit(interim, false);
    };

    recognition.onerror = function (event) {
      var code = (event && event.error) || 'unknown';

      if (code === 'no-speech') return;

      if (code === 'not-allowed' || code === 'service-not-allowed') {
        state.listening = false;
        fail('لم يُسمح باستخدام الميكروفون. اسمح بالوصول من أيقونة القفل في شريط العنوان.');
        return;
      }

      if (code === 'audio-capture') {
        state.listening = false;
        fail('لا يوجد ميكروفون متاح لهذا المتصفح.');
        return;
      }

      status('تعذّر التعرّف: ' + code);
    };

    recognition.onend = function () {
      if (!state.listening) return;

      /* المتصفح يوقف الجلسة تلقائياً كل فترة؛ نعيد تشغيلها. */
      try {
        recognition.start();
      } catch (error) {
        /* تجاهل: غالباً محاولة إعادة تشغيل متزامنة */
      }
    };

    state.recognition = recognition;
    state.listening = true;

    try {
      recognition.start();
    } catch (error) {
      fail('تعذّر بدء الاستماع: ' + error);
    }
  }

  function stopMic() {
    state.listening = false;

    if (state.recognition) {
      try {
        state.recognition.stop();
      } catch (error) {
        /* تجاهل */
      }

      state.recognition = null;
    }

    status('توقّف الاستماع.');
  }

  /* ----------------------------------------------------------
     صوت الاجتماع / التبويب — يحتاج خدمة تفريغ عبر WebSocket
     ---------------------------------------------------------- */

  function startSystemAudio(wsUrl, onText, onStatus, onError) {
    state.onText = onText;
    state.onStatus = onStatus;
    state.onError = onError;
    state.wsUrl = wsUrl || '';

    if (!navigator.mediaDevices || !navigator.mediaDevices.getDisplayMedia) {
      fail('هذا المتصفح لا يسمح بالتقاط صوت التبويب. استخدم Chrome على الحاسوب.');
      return;
    }

    if (!state.wsUrl) {
      fail('صوت الاجتماع يحتاج خدمة تفريغ صوتي (WebSocket). اضبط عنوانها من إعدادات الشاشة.');
      return;
    }

    navigator.mediaDevices
      .getDisplayMedia({ video: true, audio: true })
      .then(function (stream) {
        var audioTracks = stream.getAudioTracks();

        if (!audioTracks.length) {
          stream.getTracks().forEach(function (track) {
            track.stop();
          });
          fail('لم تُشارك صوت التبويب. اختر «مشاركة صوت التبويب» في نافذة المشاركة.');
          return;
        }

        state.captureStream = stream;

        var audioOnly = new MediaStream(audioTracks);
        var mimeType = 'audio/webm;codecs=opus';

        if (!window.MediaRecorder || !MediaRecorder.isTypeSupported(mimeType)) {
          fail('هذا المتصفح لا يدعم تسجيل الصوت المطلوب.');
          return;
        }

        var socket = new WebSocket(state.wsUrl);
        socket.binaryType = 'arraybuffer';
        state.socket = socket;

        var queued = [];

        socket.onopen = function () {
          status('متصل بخدمة التفريغ — يستمع إلى صوت الاجتماع…');
          while (queued.length) socket.send(queued.shift());
        };

        socket.onmessage = function (event) {
          try {
            var payload = JSON.parse(event.data);

            if (payload && payload.text) {
              emit(payload.text, payload.isFinal !== false);
            }
          } catch (error) {
            /* تجاهل الرسائل غير الصالحة */
          }
        };

        socket.onerror = function () {
          fail('تعذّر الاتصال بخدمة التفريغ. تحقّق من العنوان ومن تشغيل الخدمة.');
        };

        socket.onclose = function () {
          status('أُغلق اتصال خدمة التفريغ.');
        };

        var recorder = new MediaRecorder(audioOnly, {
          mimeType: mimeType,
          audioBitsPerSecond: 64000
        });

        recorder.ondataavailable = function (event) {
          if (!event.data || !event.data.size) return;

          if (socket.readyState === WebSocket.OPEN) {
            socket.send(event.data);
          } else if (socket.readyState === WebSocket.CONNECTING) {
            queued.push(event.data);
            if (queued.length > 12) queued.shift();
          }
        };

        recorder.start(4000);
        state.recorder = recorder;
        state.listening = true;
      })
      .catch(function (error) {
        fail('تعذّر التقاط صوت الاجتماع: ' + (error && error.message ? error.message : error));
      });
  }

  function stopSystemAudio() {
    state.listening = false;

    if (state.recorder) {
      try {
        state.recorder.stop();
      } catch (error) {
        /* تجاهل */
      }
      state.recorder = null;
    }

    if (state.socket) {
      try {
        state.socket.close();
      } catch (error) {
        /* تجاهل */
      }
      state.socket = null;
    }

    if (state.captureStream) {
      state.captureStream.getTracks().forEach(function (track) {
        track.stop();
      });
      state.captureStream = null;
    }

    status('توقّف الاستماع إلى صوت الاجتماع.');
  }

  /* ----------------------------------------------------------
     الترجمة — نطلبها من Flutter/Dart، وهنا ندعم CORS فقط
     ---------------------------------------------------------- */

  window.AYCVoice = {
    isSupported: function () {
      return hasSpeech();
    },

    supportsSystemAudio: function () {
      return !!(navigator.mediaDevices && navigator.mediaDevices.getDisplayMedia && window.MediaRecorder);
    },

    startMic: startMic,
    stopMic: stopMic,
    startSystemAudio: startSystemAudio,
    stopSystemAudio: stopSystemAudio,

    isListening: function () {
      return !!state.listening;
    }
  };
})();
