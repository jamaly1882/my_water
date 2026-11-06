// ============================================================
// previous_reading_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ocr/meter_analysis.dart';
import '../ocr/ocr_service.dart';
import '../widgets/my_app_bar.dart';

class PreviousReadingScreen extends StatefulWidget {
  final String? cycleId;

  const PreviousReadingScreen({
    super.key,
    this.cycleId,
  });

  @override
  State<PreviousReadingScreen> createState() =>
      _PreviousReadingScreenState();
}

class _PreviousReadingScreenState
    extends State<PreviousReadingScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController currentController =
      TextEditingController();

  // ============================================================
  // الحالة
  // ============================================================

  bool isLoading = true;
  bool isReadingImage = false;
  bool isSaving = false;

  // ============================================================
  // بيانات الدورة
  // ============================================================

  String cycleId = '';

  String customerId = '';
  String customerName = '';
  String customerPhone = '';
  String accountId = '';

  String wellId = '';
  String wellName = '';

  String waterUsageTypeName = '';

  // مهم جداً
  String meterTypeId = '';
  String meterTypeName = '';

  double unitPrice = 0;

  // ============================================================
  // عدد الوحدات المتراكم في meter_types
  // ============================================================

  int meterUnitsCount = 0;

  // ============================================================
  // القراءات
  // ============================================================

  int previousReading = 0;
  int currentReading = 0;
  int consumption = 0;

  double amount = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.cycleId != null &&
        widget.cycleId!.trim().isNotEmpty) {
      cycleId = widget.cycleId!.trim();
      loadCycle();
    } else {
      isLoading = false;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    currentController.dispose();
    super.dispose();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? Colors.red : Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // INT
  // ============================================================

  int toInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double toDouble(dynamic value) {
    if (value is double) return value;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // تحميل الدورة
  // ============================================================

  Future<void> loadCycle() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final doc = await firestore
          .collection('cycles')
          .doc(cycleId)
          .get();

      if (!doc.exists) {
        showMessage(
          'Cycle not found',
          error: true,
        );
        return;
      }

      final data = doc.data();

      if (data == null) {
        showMessage(
          'Cycle data not found',
          error: true,
        );
        return;
      }

      // ----------------------------------------------------------
      // بيانات الدورة
      // ----------------------------------------------------------

      customerId =
          data['customerId']?.toString() ?? '';

      customerName =
          data['customerName']?.toString() ?? '';

      customerPhone =
          data['customerPhone']?.toString() ?? '';

      accountId =
          data['accountId']?.toString() ?? '';

      wellId =
          data['wellId']?.toString() ?? '';

      wellName =
          data['wellName']?.toString() ?? '';

      waterUsageTypeName =
          data['waterUsageTypeName']?.toString() ?? '';

      // ==========================================================
      // مهم:
      // نحتاج meterTypeId حتى نحدث نفس سجل نوع العداد
      // ==========================================================

      meterTypeId =
          data['meterTypeId']?.toString() ?? '';

      meterTypeName =
          data['meterTypeName']?.toString() ?? '';

      unitPrice =
          toDouble(data['unitPrice']);

      previousReading =
          toInt(data['previousReading']);

      currentReading =
          toInt(data['currentReading']);

      consumption =
          toInt(data['consumption']);

      amount =
          toDouble(data['amount']);

      // ==========================================================
      // إذا لم يوجد meterTypeId داخل الدورة
      // نحاول البحث عن نوع العداد بالاسم والبئر
      // ==========================================================

      if (meterTypeId.isEmpty &&
          meterTypeName.isNotEmpty &&
          wellId.isNotEmpty) {
        final meterQuery = await firestore
            .collection('meter_types')
            .where(
              'wellId',
              isEqualTo: wellId,
            )
            .where(
              'name',
              isEqualTo: meterTypeName,
            )
            .limit(1)
            .get();

        if (meterQuery.docs.isNotEmpty) {
          meterTypeId =
              meterQuery.docs.first.id;

          final meterData =
              meterQuery.docs.first.data();

          meterUnitsCount =
              toInt(meterData['unitsCount']);
        }
      }

      // ==========================================================
      // تحميل عدد الوحدات الحالي من جدول العدادات
      // ==========================================================

      if (meterTypeId.isNotEmpty) {
        final meterDoc = await firestore
            .collection('meter_types')
            .doc(meterTypeId)
            .get();

        if (meterDoc.exists) {
          final meterData =
              meterDoc.data();

          if (meterData != null) {
            final meterWellId =
                meterData['wellId']
                        ?.toString() ??
                    '';

            // ------------------------------------------------------
            // حماية:
            // لا نستخدم عدادًا تابعًا لبئر آخر
            // ------------------------------------------------------

            if (wellId.isNotEmpty &&
                meterWellId.isNotEmpty &&
                meterWellId != wellId) {
              showMessage(
                'This meter type does not belong to the well',
                error: true,
              );

              meterTypeId = '';
              meterUnitsCount = 0;
            } else {
              meterUnitsCount =
                  toInt(
                meterData['unitsCount'],
              );

              if (meterTypeName.isEmpty) {
                meterTypeName =
                    meterData['name']
                            ?.toString() ??
                        '';
              }

              // إذا كان السعر غير موجود في الدورة
              if (unitPrice <= 0) {
                unitPrice =
                    toDouble(
                  meterData['unitPrice'],
                );
              }
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        if (_isValidMeterReading(
          currentReading.toString(),
        )) {
          currentController.text =
              currentReading.toString();
        }
      });
    } catch (e) {
      showMessage(
        'خطأ في تحميل الدورة:\n$e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // التحقق من 6 أو 7 خانات
  // ============================================================

  bool _isValidMeterReading(
    String value,
  ) {
    return MeterAnalyzer.isValid(value);
  }

  // القراءة اليدوية: أي عدد من الأرقام، بدون شرط 7 خانات
  bool _isManualDigits(String value) {
    final clean = value.trim();
    return clean.isNotEmpty &&
        RegExp(r'^\d+$').hasMatch(clean);
  }

  // ============================================================
  // تنظيف القراءة
  // ============================================================

  String normalizeMeterNumber(
    String value,
  ) {
    String number = value;

    number = number
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('D', '0')
        .replaceAll('d', '0')
        .replaceAll('Q', '0')
        .replaceAll('q', '0')
        .replaceAll('I', '1')
        .replaceAll('i', '1')
        .replaceAll('l', '1')
        .replaceAll('L', '1')
        .replaceAll('|', '1')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('B', '8')
        .replaceAll('b', '8')
        .replaceAll('G', '6')
        .replaceAll('g', '6')
        .replaceAll('Z', '2')
        .replaceAll('z', '2')
        .replaceAll('T', '7')
        .replaceAll('t', '7')
        .replaceAll('A', '4')
        .replaceAll('a', '4');

    // الأرقام العربية
    number = number
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');

    number = number.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return number;
  }

  // ============================================================
  // تنظيف القراءة اليدوية
  // يسمح بالأرقام الإنجليزية والعربية فقط.
  // لا يفرض أي عدد محدد من الخانات.
  // ============================================================

  String normalizeManualNumber(String value) {
    return value
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .trim();
  }

  // ============================================================
  // قراءة العداد
  // ============================================================

Future<void> readMeterImage() async {
  if (isReadingImage) return;

  try {
    setState(() {
      isReadingImage = true;
    });

    // تمرير context والقراءة السابقة لتحسين دقة التحليل والتحقق.
    final String? result = await OCRService.readNumber(
      context,
      previousReading: previousReading,
    );

    if (!mounted) return;

    if (result == null) {
      return;
    }

    if (result.trim().isEmpty) {
      showMessage(
        'No 6 or 7 digit reading was found',
        error: true,
      );
      return;
    }

    debugPrint('OCR RESULT: $result');

    final String number = normalizeMeterNumber(result);

    debugPrint('NORMALIZED READING: $number');

    // التحقق من أن القراءة 6 أو 7 أرقام بالضبط.
    if (!_isValidMeterReading(number)) {
      showMessage(
        'القراءة يجب أن تكون 6 أو 7 خانات بالضبط\n'
        'Extracted reading: $number',
        error: true,
      );
      return;
    }

    // التحويل للمقارنة والحساب فقط، مع الاحتفاظ بالنص
    // حتى لا نفقد الصفر الموجود في بداية القراءة.
    final int? reading = int.tryParse(number);

    if (reading == null) {
      showMessage(
        'The extracted reading is invalid',
        error: true,
      );
      return;
    }

    if (reading < previousReading) {
      showMessage(
        'القراءة الحالية أقل من القراءة السابقة\n'
        'السابقة: $previousReading\n'
        'Current: $number',
        error: true,
      );
      return;
    }

    currentController.text = number;

    calculateBill(number);

    if (!mounted) return;

    showMessage('Reading recognised: $number');

    setState(() {});
  } catch (e, stackTrace) {
    debugPrint('OCR ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    showMessage(
      'حدث خطأ أثناء قراءة الصورة:\n$e',
      error: true,
    );
  } finally {
    if (mounted) {
      setState(() {
        isReadingImage = false;
      });
    }
  }
}

  // ============================================================
  // حساب الاستهلاك
  // ============================================================

  void calculateBill(
    String value,
  ) {
    final String clean =
        value.trim();

    if (!_isManualDigits(clean)) {
      return;
    }

    final BigInt? reading =
        BigInt.tryParse(clean);

    if (reading == null) {
      return;
    }

    if (reading < BigInt.from(previousReading)) {
      setState(() {
        currentReading = 0;
        consumption = 0;
        amount = 0;
      });
      return;
    }

    // ==========================================================
    // استهلاك الدورة الحالية
    // ==========================================================

    final BigInt newConsumptionBig =
        reading - BigInt.from(previousReading);

    final BigInt maxInt =
        BigInt.parse('9223372036854775807');

    if (newConsumptionBig > maxInt) {
      return;
    }

    final int newConsumption =
        newConsumptionBig.toInt();

    if (reading > maxInt) {
      // القراءة نفسها يمكن حفظها كنص، لكن حقول الحساب القديمة
      // تعتمد على int؛ نعرض الاستهلاك فقط إذا كان قابلاً للحساب.
      currentReading = 0;
    }

    // ==========================================================
    // المبلغ
    //
    // المبلغ = استهلاك الدورة × سعر الوحدة
    // ==========================================================

    final double newAmount =
        newConsumption * unitPrice;

    setState(() {
      currentReading = reading.toInt();
      consumption = newConsumption;
      amount = newAmount;
    });
  }

  // ============================================================
  // إدخال يدوي
  // ============================================================

  void openManualInput() {
    final controller =
        TextEditingController(
      text: currentController.text,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 20,
              bottom:
                  MediaQuery.of(
                        sheetContext,
                      )
                      .viewInsets
                      .bottom +
                  20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade400,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Enter the reading manually',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      TextInputType.number,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.blue,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Current reading',
                    hintText:
                        'e.g. 9142037',
                    prefixIcon:
                        Icon(
                      Icons.speed,
                      color: Colors.blue,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment:
                      Alignment.centerRight,
                  child: Text(
                    'A manual reading can have any number of digits',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment:
                      Alignment.centerRight,
                  child: Text(
                    'Previous reading: $previousReading',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      final value =
                          normalizeManualNumber(
                        controller.text,
                      );

                      if (!_isManualDigits(value)) {
                        showMessage(
                          'A manual reading must contain digits only',
                          error: true,
                        );
                        return;
                      }

                      final reading =
                          BigInt.tryParse(value);

                      if (reading == null) {
                        showMessage(
                          'Enter a valid number',
                          error: true,
                        );
                        return;
                      }

                      if (reading <
                          BigInt.from(previousReading)) {
                        showMessage(
                          'The current reading is lower than the previous one',
                          error: true,
                        );
                        return;
                      }

                      currentController.text =
                          value;

                      calculateBill(value);

                      Navigator.pop(
                        sheetContext,
                      );

                      setState(() {});
                    },
                    icon:
                        const Icon(
                      Icons.check,
                    ),
                    label:
                        const Text(
                      'Confirm the reading',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blue,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // خيارات القراءة
  // ============================================================

  void showReadingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.grey.shade400,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  const Text(
                    'How to enter the current reading',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),

                  // ==================================================
                  // OCR
                  // ==================================================

                  Container(
                    width: double.infinity,
                    decoration:
                        BoxDecoration(
                      color: Colors.blue,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: ListTile(
                      leading:
                          const CircleAvatar(
                        backgroundColor:
                            Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          color:
                              Colors.blue,
                        ),
                      ),
                      title:
                          const Text(
                        'Photograph the meter and read the number',
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle:
                          const Text(
                        'Crop the photo, then 6 or 7 digits are read automatically',
                        style: TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        readMeterImage();
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ==================================================
                  // يدوي
                  // ==================================================

                  Container(
                    width: double.infinity,
                    decoration:
                        BoxDecoration(
                      color: Colors.blue,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: ListTile(
                      leading:
                          const CircleAvatar(
                        backgroundColor:
                            Colors.white,
                        child: Icon(
                          Icons.edit,
                          color:
                              Colors.blue,
                        ),
                      ),
                      title:
                          const Text(
                        'Enter the reading manually',
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle:
                          const Text(
                        'Manual entry with no digit limit',
                        style: TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        openManualInput();
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // صف أبيض
  // ============================================================

  Widget whiteInfoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.end,
              style:
                  const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // شريط القراءة
  // ============================================================

  Widget buildReadingBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding:
          const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.speed,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Reading details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(
            color: Colors.white38,
          ),
          whiteInfoRow(
            'Previous reading',
            previousReading.toString(),
          ),
          whiteInfoRow(
            'Current reading',
            currentReading == 0
                ? 'Not recorded'
                : currentReading.toString(),
          ),
          whiteInfoRow(
            'Consumption this cycle',
            '$consumption units',
          ),
          whiteInfoRow(
            'Units before this cycle',
            '$meterUnitsCount units',
          ),
          whiteInfoRow(
            'After this cycle',
            '${meterUnitsCount + consumption} units',
          ),
          whiteInfoRow(
            'Amount',
            '$amount YER',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة المشترك
  // ============================================================

  Widget buildCustomerCard() {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  'Subscriber details',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            infoRow(
              'Subscriber name',
              customerName,
            ),
            infoRow(
              'Account number',
              accountId,
            ),
            infoRow(
              'Phone',
              customerPhone,
            ),
            infoRow(
              'Well',
              wellName,
            ),
            infoRow(
              'Usage type',
              waterUsageTypeName,
            ),
            infoRow(
              'Meter type',
              meterTypeName,
            ),
            infoRow(
              'Unit price',
              '$unitPrice YER',
            ),
            infoRow(
              'Accumulated units',
              '$meterUnitsCount units',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // info row
  // ============================================================

  Widget infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value.isEmpty
                  ? 'Not set'
                  : value,
              textAlign:
                  TextAlign.end,
              style:
                  const TextStyle(
                color: Colors.black87,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // القراءة الحالية
  // ============================================================

  Widget buildCurrentReadingCard() {
    if (!_isManualDigits(
      currentController.text.trim(),
    )) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding:
          const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Current reading',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            currentController.text,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight:
                  FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Consumption this cycle: $consumption units',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Total after adding: '
                  '${meterUnitsCount + consumption} units',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Amount: $amount YER',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // الحساب
  // ============================================================

  Widget buildAccountingCard() {
    if (amount <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding:
          const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Accounting entry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(
            color: Colors.white38,
          ),
          whiteInfoRow(
            'Debit — subscriber account',
            '$amount YER',
          ),
          whiteInfoRow(
            'Credit — well sales',
            '$amount YER',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // الزر
  // ============================================================

  Widget blueButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String text,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child:
          ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 23,
                height: 23,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          text,
          style:
              const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              Colors.blue,
          foregroundColor:
              Colors.white,
          elevation: 3,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // الحفظ
  //
  // هنا أهم تعديل في الصفحة
  // ============================================================

  Future<void> saveCurrentReading() async {
    if (isSaving) return;

    if (cycleId.isEmpty) {
      showMessage(
        'Cycle ID is missing',
        error: true,
      );
      return;
    }

    final value =
        normalizeManualNumber(
      currentController.text,
    );

    // ==========================================================
    // القراءة اليدوية: أي عدد من الخانات بشرط أن تكون أرقاماً فقط
    // ==========================================================

    if (!_isManualDigits(value)) {
      showMessage(
        'The current reading must contain digits only',
        error: true,
      );
      return;
    }

    final reading =
        BigInt.tryParse(value);

    if (reading == null) {
      showMessage(
        'The reading must be a valid number',
        error: true,
      );
      return;
    }

    if (reading < BigInt.from(previousReading)) {
      showMessage(
        'The current reading is lower than the previous one',
        error: true,
      );
      return;
    }

    calculateBill(value);

    if (consumption < 0) {
      showMessage(
        'The consumption value is invalid',
        error: true,
      );
      return;
    }

    if (meterTypeId.isEmpty) {
      showMessage(
        'The meter type ID is missing from the cycle',
        error: true,
      );
      return;
    }

    if (wellId.isEmpty) {
      showMessage(
        'The well ID is missing',
        error: true,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // ========================================================
      // جميع العملية داخل Transaction
      //
      // هذا مهم جداً حتى لا يحدث:
      //
      // الدورة الأولى = 100
      // الدورة الثانية = 100
      //
      // ويضيع أحدهما بسبب الحفظ المتزامن.
      // ========================================================

      await firestore.runTransaction(
        (transaction) async {
          // ======================================================
          // 1. قراءة الدورة
          // ======================================================

          final cycleRef = firestore
              .collection('cycles')
              .doc(cycleId);

          final cycleDoc =
              await transaction.get(
            cycleRef,
          );

          if (!cycleDoc.exists) {
            throw Exception(
              'Cycle not found',
            );
          }

          final cycleData =
              cycleDoc.data();

          if (cycleData == null) {
            throw Exception(
              'Cycle data not found',
            );
          }

          final status =
              cycleData['status']
                      ?.toString() ??
                  '';

          // ======================================================
          // حماية من تسجيل نفس الدورة مرتين
          // ======================================================

          if (status != 'Open') {
            throw Exception(
              'This cycle is already closed',
            );
          }

          // ======================================================
          // 2. قراءة نوع العداد
          // ======================================================

          final meterRef = firestore
              .collection('meter_types')
              .doc(meterTypeId);

          final meterDoc =
              await transaction.get(
            meterRef,
          );

          if (!meterDoc.exists) {
            throw Exception(
              'Meter type not found',
            );
          }

          final meterData =
              meterDoc.data();

          if (meterData == null) {
            throw Exception(
              'Meter type data not found',
            );
          }

          // ======================================================
          // التأكد أن نوع العداد تابع لنفس البئر
          // ======================================================

          final meterWellId =
              meterData['wellId']
                      ?.toString() ??
                  '';

          if (meterWellId.isNotEmpty &&
              meterWellId != wellId) {
            throw Exception(
              'This meter type does not belong to the selected well',
            );
          }

          // ======================================================
          // التأكد من الاسم
          // ======================================================

          final currentMeterName =
              meterData['name']
                      ?.toString() ??
                  meterTypeName;

          // ======================================================
          // عدد الوحدات القديم
          //
          // مثال:
          //
          // الطاقة الشمسية = 100
          // ======================================================

          final int oldUnitsCount =
              toInt(
            meterData['unitsCount'],
          );

          // ======================================================
          // عدد الوحدات الجديد
          //
          // مثال:
          //
          // القديم = 100
          // استهلاك الدورة = 100
          //
          // الجديد = 200
          // ======================================================

          final int newUnitsCount =
              oldUnitsCount + consumption;

          // ======================================================
          // 3. حساب مبيعات البئر
          // ======================================================

          QuerySnapshot<
                  Map<String, dynamic>>
              salesQuery;

          if (wellId.isNotEmpty) {
            salesQuery = await firestore
                .collection('accounts')
                .where(
                  'wellId',
                  isEqualTo: wellId,
                )
                .where(
                  'type',
                  isEqualTo: 'sales',
                )
                .limit(1)
                .get();
          } else {
            salesQuery = await firestore
                .collection('accounts')
                .where(
                  'type',
                  isEqualTo: 'sales',
                )
                .limit(1)
                .get();
          }

          // ======================================================
          // 4. حساب المشترك
          // ======================================================

          QuerySnapshot<
                  Map<String, dynamic>>
              customerQuery;

          if (accountId.isNotEmpty) {
            final accountDoc =
                await firestore
                    .collection('accounts')
                    .doc(accountId)
                    .get();

            if (accountDoc.exists) {
              customerQuery =
                  await firestore
                      .collection('accounts')
                      .where(
                        FieldPath
                            .documentId,
                        isEqualTo:
                            accountId,
                      )
                      .limit(1)
                      .get();
            } else {
              customerQuery =
                  await firestore
                      .collection('accounts')
                      .where(
                        'customerId',
                        isEqualTo:
                            customerId,
                      )
                      .limit(1)
                      .get();
            }
          } else {
            customerQuery =
                await firestore
                    .collection('accounts')
                    .where(
                      'customerId',
                      isEqualTo:
                          customerId,
                    )
                    .limit(1)
                    .get();
          }

          // ======================================================
          // التأكد من الحسابات
          // ======================================================

          if (salesQuery.docs.isEmpty) {
            throw Exception(
              'No sales account found for the well',
            );
          }

          if (customerQuery.docs.isEmpty) {
            throw Exception(
              'No financial account found for the subscriber',
            );
          }

          final salesDoc =
              salesQuery.docs.first;

          final customerDoc =
              customerQuery.docs.first;

          final salesData =
              salesDoc.data();

          final customerData =
              customerDoc.data();

          // ======================================================
          // الأرصدة القديمة
          // ======================================================

          final oldSalesBalance =
              toDouble(
            salesData['balance'],
          );

          final oldSalesCredit =
              toDouble(
            salesData['credit'],
          );

          final oldCustomerBalance =
              toDouble(
            customerData['balance'],
          );

          final oldCustomerDebit =
              toDouble(
            customerData['debit'],
          );

          // ======================================================
          // 5. تحديث الدورة
          //
          // مهم:
          // لا نغير endDate القديم هنا.
          //
          // إذا كان endDate محدداً من شاشة فتح الدورة
          // يبقى كما هو.
          // ======================================================

          transaction.update(
            cycleRef,
            {
              'previousReading':
                  previousReading,

              'currentReading':
                  currentReading,

              'consumption':
                  consumption,

              // ==================================================
              // حفظ الإجمالي الحالي
              // ==================================================

              'totalConsumption':
                  consumption,

              // ==================================================
              // حفظ قيمة الوحدات التراكمية بعد هذه الدورة
              // ==================================================

              'unitsCount':
                  newUnitsCount,

              'meterTypeId':
                  meterTypeId,

              'meterTypeName':
                  currentMeterName,

              'unitPrice':
                  unitPrice,

              'amount':
                  amount,

              'status':
                  'Closed',

              // لا نلمس endDate
              //
              // نسجل وقت الإغلاق في closedAt
              'closedAt':
                  FieldValue.serverTimestamp(),

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // ======================================================
          // 6. تحديث جدول أنواع العدادات
          //
          // هذا هو التعديل الأساسي المطلوب
          //
          // القديم + استهلاك الدورة الحالية
          // ======================================================

          transaction.update(
            meterRef,
            {
              'unitsCount':
                  newUnitsCount,

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // ======================================================
          // 7. تحديث حساب المبيعات
          // ======================================================

          transaction.update(
            salesDoc.reference,
            {
              'credit':
                  oldSalesCredit + amount,

              'balance':
                  oldSalesBalance + amount,

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // ======================================================
          // 8. تحديث حساب المشترك
          // ======================================================

          transaction.update(
            customerDoc.reference,
            {
              'debit':
                  oldCustomerDebit + amount,

              'balance':
                  oldCustomerBalance + amount,

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // ======================================================
          // 9. حركة المبيعات
          // ======================================================

          final salesTransaction =
              firestore
                  .collection(
                    'account_transactions',
                  )
                  .doc();

          transaction.set(
            salesTransaction,
            {
              'transactionId':
                  salesTransaction.id,

              'accountId':
                  salesDoc.id,

              'customerId':
                  customerId,

              'customerName':
                  customerName,

              'wellId':
                  wellId,

              'wellName':
                  wellName,

              'cycleId':
                  cycleId,

              'meterTypeId':
                  meterTypeId,

              'meterTypeName':
                  currentMeterName,

              'type':
                  'sales',

              'transactionType':
                  'credit',

              'debit':
                  0,

              'credit':
                  amount,

              'amount':
                  amount,

              'balance':
                  oldSalesBalance +
                      amount,

              'description':
                  'Water sales — meter reading',

              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // ======================================================
          // 10. حركة المشترك
          // ======================================================

          final customerTransaction =
              firestore
                  .collection(
                    'account_transactions',
                  )
                  .doc();

          transaction.set(
            customerTransaction,
            {
              'transactionId':
                  customerTransaction.id,

              'accountId':
                  customerDoc.id,

              'customerId':
                  customerId,

              'customerName':
                  customerName,

              'wellId':
                  wellId,

              'wellName':
                  wellName,

              'cycleId':
                  cycleId,

              'meterTypeId':
                  meterTypeId,

              'meterTypeName':
                  currentMeterName,

              'type':
                  'customer',

              'transactionType':
                  'debit',

              'debit':
                  amount,

              'credit':
                  0,

              'amount':
                  amount,

              'balance':
                  oldCustomerBalance +
                      amount,

              'description':
                  'Water consumption — meter reading',

              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );

      // ==========================================================
      // تحديث القيمة المعروضة محلياً
      // ==========================================================

      meterUnitsCount =
          meterUnitsCount + consumption;

      if (!mounted) return;

      showMessage(
        'تم حفظ القراءة وإغلاق الدورة\n'
        'Consumption this cycle: $consumption units\n'
        'Meter type units total: $meterUnitsCount units',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 900,
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      String message =
          e.toString();

      if (message.startsWith(
        'Exception: ',
      )) {
        message =
            message.substring(
          'Exception: '.length,
        );
      }

      showMessage(
        'حدث خطأ أثناء الحفظ:\n$message',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF5F8FC),

        appBar:
            const MyAppBar(
          title:
              'Save the reading',
          showBackButton: true,
          icon: Icons.speed,
        ),

        body: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: Colors.blue,
                ),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  children: [
                    // ==================================================
                    // رأس الصفحة
                    // ==================================================

                    Container(
                      width:
                          double.infinity,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.blue,
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color:
                                Colors.black26,
                            blurRadius: 7,
                            offset:
                                Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),
                      padding:
                          const EdgeInsets
                              .all(
                        16,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 27,
                            backgroundColor:
                                Colors.white,
                            child: Icon(
                              Icons.speed,
                              color:
                                  Colors.blue,
                              size: 30,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  customerName
                                          .isEmpty
                                      ? 'Subscriber'
                                      : customerName,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        19,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  'Previous reading: $previousReading',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white70,
                                    fontSize:
                                        14,
                                  ),
                                ),
                                if (wellName
                                    .isNotEmpty)
                                  Text(
                                    'Well: $wellName',
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white70,
                                      fontSize:
                                          13,
                                    ),
                                  ),
                                if (meterTypeName
                                    .isNotEmpty)
                                  Text(
                                    'Meter type: $meterTypeName',
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white70,
                                      fontSize:
                                          13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    buildCustomerCard(),

                    const SizedBox(
                      height: 15,
                    ),

                    buildReadingBar(),

                    const SizedBox(
                      height: 18,
                    ),

                    blueButton(
                      onPressed:
                          isReadingImage
                              ? null
                              : showReadingOptions,
                      icon:
                          Icons.speed,
                      text: isReadingImage
                          ? 'Reading the meter…'
                          : 'Enter the current reading',
                      loading:
                          isReadingImage,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    buildCurrentReadingCard(),

                    const SizedBox(
                      height: 15,
                    ),

                    buildAccountingCard(),

                    const SizedBox(
                      height: 22,
                    ),

                    blueButton(
                      onPressed:
                          isSaving ||
                                  isReadingImage
                              ? null
                              : saveCurrentReading,
                      icon: Icons
                          .account_balance,
                      text: isSaving
                          ? 'Saving…'
                          : 'Post the entry and close the cycle',
                      loading:
                          isSaving,
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
