import 'package:flutter/material.dart';

import '../../services/ai_agent_query_service.dart';

class AiAgentPage extends StatefulWidget {
  const AiAgentPage({
    super.key,
  });

  @override
  State<AiAgentPage> createState() =>
      _AiAgentPageState();
}

class _AiAgentPageState
    extends State<AiAgentPage> {
  final TextEditingController
      _messageController =
      TextEditingController();

  final ScrollController
      _scrollController =
      ScrollController();

  bool _loading = false;

  String? _error;

  String _answer = '';

  String _wellName = '';

  final List<_ChatMessage> _messages = [];

  Future<void> _askAgent() async {
    final String message =
        _messageController.text.trim();

    if (message.isEmpty) {
      setState(() {
        _error = 'اكتب سؤالك أولاً.';
      });

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _error = null;
      _loading = true;

      _messages.add(
        _ChatMessage(
          text: message,
          isUser: true,
        ),
      );
    });

    _messageController.clear();

    _scrollToBottom();

    try {
      final Map<String, dynamic> response =
          await AiAgentQueryService.ask(
        message: message,
      );

      final String answer =
          response['answer']?.toString() ??
              '';

      final String wellName =
          response['wellName']?.toString() ??
              '';

      if (!mounted) return;

      setState(() {
        _answer = answer;

        if (wellName.isNotEmpty) {
          _wellName = wellName;
        }

        _messages.add(
          _ChatMessage(
            text: answer.isEmpty
                ? 'لم يتم إرجاع إجابة.'
                : answer,
            isUser: false,
          ),
        );

        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(
          e.toString(),
        );

        _messages.add(
          _ChatMessage(
            text: _cleanError(
              e.toString(),
            ),
            isUser: false,
            isError: true,
          ),
        );
      });

      _scrollToBottom();
    }
  }

  String _cleanError(String error) {
    if (error.startsWith(
      'Exception: ',
    )) {
      return error.substring(
        'Exception: '.length,
      );
    }

    return error;
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _answer = '';
      _error = null;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController
            .position
            .maxScrollExtent,
        duration:
            const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessage(
    _ChatMessage message,
  ) {
    final bool isUser =
        message.isUser;

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 700,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isError
              ? Colors.red.shade50
              : isUser
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  isUser
                      ? Icons.person
                      : Icons.auto_awesome,
                  size: 18,
                  color: message.isError
                      ? Colors.red
                      : null,
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  isUser
                      ? 'أنت'
                      : 'مساعد البئر',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            SelectableText(
              message.text,
              style:
                  const TextStyle(
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Card(
      elevation: 1,
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  child: const Icon(
                    Icons.water_drop,
                    size: 28,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                const Expanded(
                  child: Text(
                    'مساعد إدارة البئر',
                    style:
                        TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              _wellName.isEmpty
                  ? 'اسألني عن بيانات البئر المرتبط بحسابك.'
                  : 'البئر الحالي: $_wellName',
              style:
                  TextStyle(
                color:
                    Colors.grey.shade700,
                height: 1.6,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'يمكنك أن تسأل بطريقة طبيعية، مثل:',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              '• اعرض لي عملائي\n'
              '• اعرض قراءات عملائي\n'
              '• اعرض حساباتهم\n'
              '• من عليه مديونية؟\n'
              '• اعرض سندات الصرف\n'
              '• كم إجمالي الاستهلاك؟\n'
              '• اعرض قيمة صقر عبد الله جمال',
              style:
                  TextStyle(
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'مساعد البئر بالذكاء الاصطناعي',
          ),
          centerTitle: true,
          actions: [
            if (_messages.isNotEmpty)
              IconButton(
                tooltip: 'مسح المحادثة',
                onPressed: _loading
                    ? null
                    : _clearChat,
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller:
                    _scrollController,
                padding:
                    const EdgeInsets.all(16),
                children: [
                  if (_messages.isEmpty)
                    _buildWelcome(),

                  if (_messages.isNotEmpty)
                    ..._messages.map(
                      _buildMessage,
                    ),

                  if (_loading)
                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'جاري التفكير والبحث...',
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_error != null)
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                padding:
                    const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  _error!,
                  style:
                      const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),

            SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Theme.of(context)
                          .scaffoldBackgroundColor,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            _messageController,
                        minLines: 1,
                        maxLines: 5,
                        textDirection:
                            TextDirection.rtl,
                        textInputAction:
                            TextInputAction.newline,
                        enabled: !_loading,
                        decoration:
                            InputDecoration(
                          hintText:
                              'اكتب سؤالك هنا...',
                          border:
                              const OutlineInputBorder(),
                          filled: true,
                          suffixIcon:
                              _messageController
                                      .text
                                      .isNotEmpty
                                  ? IconButton(
                                      onPressed:
                                          _loading
                                              ? null
                                              : () {
                                                  _messageController
                                                      .clear();
                                                  setState(
                                                    () {},
                                                  );
                                                },
                                      icon:
                                          const Icon(
                                        Icons.clear,
                                      ),
                                    )
                                  : null,
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                        onSubmitted:
                            (_) {
                          if (!_loading) {
                            _askAgent();
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    SizedBox(
                      height: 56,
                      width: 56,
                      child: FilledButton(
                        onPressed:
                            _loading
                                ? null
                                : _askAgent,
                        style:
                            FilledButton
                                .styleFrom(
                          padding:
                              EdgeInsets.zero,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}


class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}