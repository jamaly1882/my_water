
// ============================================================
// open_cycle_screen.dart
// صفحة إضافة / فتح دور مياه جديد
//
// التعديل:
// - الإدخال اليدوي يقبل أي عدد من الأرقام.
// - OCR: تصوير العداد ثم قص شاشة الأرقام يدويًا ثم قراءة 6 أو 7 أرقام بالضبط.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ocr/meter_analysis.dart';
import '../ocr/ocr_service.dart';
import '../widgets/my_app_bar.dart';

class OpenCycleScreen extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic> customerData;

  final String? supervisorId;

  final String? provinceId;
  final String? provinceName;

  final String? districtId;
  final String? districtName;

  final String? hamletId;
  final String? hamletName;

  final String? villageId;
  final String? villageName;

  final String? wellId;
  final String? wellName;

  const OpenCycleScreen({
    super.key,
    required this.customerId,
    required this.customerData,
    this.supervisorId,
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
    this.hamletId,
    this.hamletName,
    this.villageId,
    this.villageName,
    this.wellId,
    this.wellName,
  });

  @override
  State<OpenCycleScreen> createState() => _OpenCycleScreenState();
}

class _OpenCycleScreenState extends State<OpenCycleScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color appColor = Colors.blue;

  static const Color backgroundColor = Color(0xffF5F9FF);

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late TabController _tabController;

  final TextEditingController readingController =
      TextEditingController();

  // ============================================================
  // STATES
  // ============================================================

  bool _isLoadingOcr = false;
  bool _isSaving = false;

  // ============================================================
  // CUSTOMER
  // ============================================================

  late String customerId;

  String customerName = "";
  String customerPhone = "";
  String customerAddress = "";

  String accountId = "";

  String waterUsageTypeId = "";
  String waterUsageTypeName = "";

  // ============================================================
  // METER
  // ============================================================

  String meterTypeId = "";
  String meterTypeName = "";

  double unitPrice = 0;

  // ============================================================
  // READING
  // ============================================================

  String previousReading = "";

  int cycleNumber = 0;

  // ============================================================
  // DATES
  // ============================================================

  DateTime? startDate;
  DateTime? endDate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    customerId = widget.customerId;

    final data = widget.customerData;

    customerName =
        data["name"]?.toString() ?? "";

    customerPhone =
        data["phone"]?.toString() ?? "";

    customerAddress =
        data["address"]?.toString() ?? "";

    accountId =
        data["accountId"]?.toString() ??
            data["accountNumber"]?.toString() ??
            "";

    waterUsageTypeId =
        data["waterUsageTypeId"]?.toString() ?? "";

    waterUsageTypeName =
        data["waterUsageTypeName"]?.toString() ?? "";

    meterTypeId =
        data["meterTypeId"]?.toString() ?? "";

    meterTypeName =
        data["meterTypeName"]?.toString() ?? "";

    unitPrice =
        _readPrice(data["unitPrice"]);

    previousReading = "";

    readingController.clear();

    cycleNumber =
        _readInt(data["cycleNumber"]);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _readPrice(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? "0",
        ) ??
        0;
  }

  int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? "0",
        ) ??
        0;
  }

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    Color? color,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // VALIDATE MANUAL READING
  //
  // الإدخال اليدوي:
  // يقبل أي عدد من الأرقام، بشرط ألا يكون فارغًا.
  //
  // أمثلة مقبولة:
  // 1
  // 12
  // 123456
  // 1234567
  // 123456789
  // ============================================================

  bool isValidReading(String value) {
    if (value.trim().isEmpty) {
      return false;
    }

    return RegExp(
      r'^\d+$',
    ).hasMatch(value.trim());
  }

  // ============================================================
  // NORMALIZE OCR / MANUAL READING
  // ============================================================

  String normalizeMeterNumber(String value) {
    String number = value.trim();

    // ----------------------------------------------------------
    // Arabic digits
    // ----------------------------------------------------------

    const arabicDigits = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    arabicDigits.forEach(
      (arabic, english) {
        number = number.replaceAll(
          arabic,
          english,
        );
      },
    );

    // ----------------------------------------------------------
    // OCR common mistakes
    // ----------------------------------------------------------

    number = number
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('D', '0')
        .replaceAll('d', '0')
        .replaceAll('Q', '0')
        .replaceAll('q', '0')
        .replaceAll('I', '1')
        .replaceAll('i', '1')
        .replaceAll('L', '1')
        .replaceAll('l', '1')
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

    // ----------------------------------------------------------
    // Remove anything except numbers
    // ----------------------------------------------------------

    number = number.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return number;
  }

  // ============================================================
  // OCR
  //
  // المسار: الكاميرا -> القص اليدوي -> OCR.
  // OCR يشترط 6 أو 7 أرقام بالضبط.
  // ============================================================

Future<void> readMeterImage() async {
  if (_isLoadingOcr || !mounted) return;

  setState(() {
    _isLoadingOcr = true;
  });

  try {
    debugPrint("======================================");
    debugPrint("START METER OCR");

    // فتح واجهة OCR وتمرير context.
    final String? result =
        await OCRService.readNumber(context);

    debugPrint("OCR RAW RESULT: $result");

    if (!mounted) return;

    // التحقق من نتيجة OCR.
    if (result == null || result.trim().isEmpty) {
      showMessage(
        "لم يتم العثور على قراءة العداد.\n\n"
        "Make sure the meter photo is clear and the digit window is fully visible.",
        color: Colors.orange,
      );
      return;
    }

    // توحيد الأرقام العربية والإنجليزية ومعالجة نتيجة OCR.
    final String number = normalizeMeterNumber(result);

    debugPrint("OCR NORMALIZED: $number");

    // يجب أن تكون القراءة 6 أو 7 أرقام بالضبط، دون إضافة أصفار.
    if (!MeterAnalyzer.isValid(number)) {
      showMessage(
        "تمت قراءة:\n$number\n\n"
        "قراءة العداد بالصورة يجب أن تكون 6 أو 7 خانات بالضبط.\n\n"
        "Retake the photo and make sure every integer digit is visible.",
        color: Colors.orange,
      );
      return;
    }

    // الاحتفاظ بالقراءة كنص حتى لا يختفي الصفر الأول.
    setState(() {
      readingController.text = number;
      previousReading = number;
    });

    // الانتقال إلى تبويب الإدخال اليدوي لعرض القراءة.
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }

    showMessage(
      "Meter read successfully: $number",
      color: Colors.green,
    );

    debugPrint("OCR SUCCESS: $number");
    debugPrint("======================================");
  } catch (e, stackTrace) {
    debugPrint("OCR ERROR: $e");
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    showMessage(
      "حدث خطأ أثناء قراءة العداد:\n$e",
      color: Colors.red,
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingOcr = false;
      });
    }
  }
}


  // ============================================================
  // LOCATION BAR
  // ============================================================

  Widget buildLocationTitleBar() {
    final locations = <String>[];

    void addLocation(String? value) {
      if (value != null &&
          value.trim().isNotEmpty) {
        locations.add(value.trim());
      }
    }

    addLocation(widget.provinceName);
    addLocation(widget.districtName);
    addLocation(widget.hamletName);
    addLocation(widget.villageName);
    addLocation(widget.wellName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      color: appColor,
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: Colors.white,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: locations.isEmpty
                ? const Text(
                    "Open a new water cycle",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Wrap(
                    spacing: 3,
                    runSpacing: 4,
                    children: [
                      for (int i = 0;
                          i < locations.length;
                          i++)
                        Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              locations[i],
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            if (i <
                                locations.length - 1)
                              const Icon(
                                Icons.chevron_left,
                                color:
                                    Colors.white70,
                                size: 18,
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER CARD
  // ============================================================

  Widget buildCustomerCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: appColor,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    customerName.isEmpty
                        ? "No name"
                        : customerName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            infoRow(
              "Phone",
              customerPhone,
              Icons.phone,
            ),

            infoRow(
              "Address",
              customerAddress,
              Icons.location_on,
            ),

            infoRow(
              "Account",
              accountId.isEmpty
                  ? "Not set"
                  : accountId,
              Icons.account_balance,
            ),

            infoRow(
              "Usage type",
              waterUsageTypeName.isEmpty
                  ? "Not set"
                  : waterUsageTypeName,
              Icons.water_drop,
            ),

            if (widget.wellName != null &&
                widget.wellName!.trim().isNotEmpty)
              infoRow(
                "Well",
                widget.wellName!,
                Icons.water,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget infoRow(
    String title,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: appColor,
          ),

          const SizedBox(width: 8),

          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty
                  ? "Not set"
                  : value,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // METER TYPES
  // ============================================================

  Widget buildMeterTypeSelector() {
    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 40,
              ),

              const SizedBox(height: 8),

              const Text(
                "No well selected",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "Cannot show the meter types for this well.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection("meter_types")
          .where(
            "wellId",
            isEqualTo: widget.wellId,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: appColor,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 40,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Could not load the meter types",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.speed_outlined,
                    color: Colors.orange,
                    size: 45,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "No meter types on this well",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    widget.wellName ??
                        "Selected well",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        String? selected;

        if (meterTypeId.isNotEmpty &&
            docs.any(
              (doc) =>
                  doc.id == meterTypeId,
            )) {
          selected = meterTypeId;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.speed,
                      color: appColor,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        "Meter types in ${widget.wellName ?? "هذا البئر"}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selected,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(
                    labelText: "Meter type",
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.speed,
                      color: appColor,
                    ),
                  ),
                  items: docs.map((doc) {
                    final data = doc.data();

                    final name =
                        data["name"]?.toString() ??
                            "No name";

                    final price =
                        _readPrice(
                      data["unitPrice"],
                    );

                    return DropdownMenuItem<
                        String>(
                      value: doc.id,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            "${_formatPrice(price)} YER",
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              color: appColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final doc =
                        docs.firstWhere(
                      (doc) =>
                          doc.id == value,
                    );

                    final data = doc.data();

                    final price =
                        _readPrice(
                      data["unitPrice"],
                    );

                    setState(() {
                      meterTypeId = doc.id;

                      meterTypeName =
                          data["name"]
                                  ?.toString() ??
                              "";

                      unitPrice = price;
                    });
                  },
                ),

                if (meterTypeId.isNotEmpty &&
                    selected != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 12,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(12),
                      decoration:
                          BoxDecoration(
                        color:
                            appColor.withValues(alpha: .06),
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        border: Border.all(
                          color:
                              appColor.withValues(alpha: .2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  "Selected type",
                                  style: TextStyle(
                                    color:
                                        Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),

                                Text(
                                  meterTypeName,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Price",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),

                              Text(
                                "${_formatPrice(unitPrice)} YER",
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 18,
                                  color: appColor,
                                ),
                              ),
                            ],
                          ),
                        ],
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
  // PRICE CARD
  // ============================================================

  Widget buildPriceCard() {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.price_check,
          color: appColor,
        ),

        title: const Text(
          "Unit price",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          meterTypeName.isEmpty
              ? "Choose the meter type for this well"
              : meterTypeName,
        ),

        trailing: Text(
          "${_formatPrice(unitPrice)} YER",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // READING CARD
  // ============================================================

  Widget buildReadingCard() {
    final value =
        readingController.text.trim();

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: appColor,
          child: Icon(
            Icons.speed,
            color: Colors.white,
          ),
        ),

        title: const Text(
          "Opening reading",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          value.isEmpty
              ? "No reading entered"
              : value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: appColor,
          ),
        ),

        trailing: const Icon(
          Icons.edit,
          color: appColor,
        ),

        onTap: showReadingOptions,
      ),
    );
  }

  // ============================================================
  // READING OPTIONS
  // ============================================================

  void showReadingOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom:
                  MediaQuery.of(sheetContext)
                          .viewInsets
                          .bottom +
                      20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  "Opening reading",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "يمكنك إدخال القراءة يدويًا بأي عدد من الخانات،\n"
                  "Or photograph the meter and crop the digit window manually; the reading must be 6 or 7 digits.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // OCR
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child:
                      ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          appColor,
                      foregroundColor:
                          Colors.white,
                    ),
                    onPressed:
                        _isLoadingOcr
                            ? null
                            : () async {
                                Navigator.pop(
                                  sheetContext,
                                );

                                await readMeterImage();
                              },
                    icon: _isLoadingOcr
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                          ),
                    label: Text(
                      _isLoadingOcr
                          ? "Reading…"
                          : "Photograph, crop and read the meter",
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ==================================================
                // MANUAL
                //
                // لا يوجد maxLength: 7
                // ==================================================

                TextField(
                  controller:
                      readingController,
                  keyboardType:
                      TextInputType.number,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Manual reading",
                    hintText:
                        "Enter any number of digits",
                    border:
                        OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.speed),
                  ),
                  onChanged: (value) {
                    final normalized =
                        normalizeMeterNumber(
                      value,
                    );

                    if (normalized != value) {
                      readingController
                        ..text = normalized
                        ..selection =
                            TextSelection
                                .fromPosition(
                          TextPosition(
                            offset:
                                normalized
                                    .length,
                          ),
                        );
                    }

                    setState(() {
                      previousReading =
                          normalized;
                    });
                  },
                ),

                const SizedBox(height: 15),

                // ==================================================
                // CONFIRM MANUAL READING
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child:
                      ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          appColor,
                      foregroundColor:
                          Colors.white,
                    ),
                    icon: const Icon(
                      Icons.check,
                    ),
                    label: const Text(
                      "Confirm reading",
                    ),
                    onPressed: () {
                      final value =
                          normalizeMeterNumber(
                        readingController
                            .text,
                      );

                      // ------------------------------------------------
                      // MANUAL:
                      // أي عدد من الأرقام مسموح
                      // ------------------------------------------------

                      if (!isValidReading(
                        value,
                      )) {
                        showMessage(
                          "Enter a valid reading with one digit or more.",
                          color:
                              Colors.red,
                        );
                        return;
                      }

                      setState(() {
                        readingController
                            .text = value;

                        previousReading =
                            value;
                      });

                      Navigator.pop(
                        sheetContext,
                      );
                    },
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
  // READING TABS
  // ============================================================

  Widget buildReadingTabs() {
    return Card(
      clipBehavior:
          Clip.antiAlias,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: appColor,
            indicatorColor: appColor,
            tabs: const [
              Tab(
                icon:
                    Icon(Icons.edit),
                text: "Manual entry",
              ),
              Tab(
                icon: Icon(
                    Icons.camera_alt),
                text: "Meter photo",
              ),
            ],
          ),

          SizedBox(
            height: 220,
            child: TabBarView(
              controller:
                  _tabController,
              children: [
                buildManualReading(),
                buildOcrReading(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MANUAL READING
  // ============================================================

  Widget buildManualReading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Text(
            "Enter the opening meter reading",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Any number of digits is accepted",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller:
                readingController,
            keyboardType:
                TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
              color: appColor,
            ),
            decoration:
                const InputDecoration(
              labelText:
                  "Manual reading",
              hintText:
                  "e.g. 123456",
              border:
                  OutlineInputBorder(),
            ),
            onChanged: (value) {
              final normalized =
                  normalizeMeterNumber(
                value,
              );

              if (normalized != value) {
                readingController
                  ..text = normalized
                  ..selection =
                      TextSelection
                          .fromPosition(
                    TextPosition(
                      offset:
                          normalized
                              .length,
                    ),
                  );
              }

              setState(() {
                previousReading =
                    normalized;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OCR TAB
  // ============================================================

  Widget buildOcrReading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner,
            size: 55,
            color:
                appColor.withValues(alpha: .7),
          ),

          const SizedBox(height: 10),

          const Text(
            "صوّر العداد ثم حدد شاشة الأرقام بالقص اليدوي.\n"
            "After cropping the digits are read automatically; it must be 6 or 7 digits.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 52,
            child:
                ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    appColor,
                foregroundColor:
                    Colors.white,
              ),
              onPressed:
                  _isLoadingOcr
                      ? null
                      : readMeterImage,
              icon: _isLoadingOcr
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                    ),
              label: Text(
                _isLoadingOcr
                    ? "Reading…"
                    : "Photograph, crop and read the meter",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTED READING
  // ============================================================

  Widget buildSelectedReading() {
    final value =
        readingController.text.trim();

    if (value.isEmpty) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.orange,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  "The opening reading has not been entered yet",
                  style: TextStyle(
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color:
          appColor.withValues(alpha: .08),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text(
              "Opening reading",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              value,
              style: const TextStyle(
                fontSize: 34,
                fontWeight:
                    FontWeight.bold,
                color: appColor,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Saved as the cycle opening reading",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE + TIME
  // ============================================================

  Future<void> selectDate(bool start) async {
    // ----------------------------------------------------------
    // Current / initial date
    // ----------------------------------------------------------

    final now = DateTime.now();

    DateTime initialDate;

    if (start) {
      initialDate =
          startDate ?? now;
    } else {
      initialDate =
          endDate ??
              startDate ??
              now;
    }

    // ----------------------------------------------------------
    // Keep date inside DatePicker limits
    // ----------------------------------------------------------

    if (initialDate.isBefore(
      DateTime(2020),
    )) {
      initialDate =
          DateTime(2020);
    }

    if (initialDate.isAfter(
      DateTime(2035, 12, 31),
    )) {
      initialDate =
          DateTime(2035, 12, 31);
    }

    // ==========================================================
    // DATE PICKER
    // ==========================================================

    final date = await showDatePicker(
      context: context,

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2035, 12, 31),

      initialDate:
          DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      ),

      helpText: start
          ? "Pick the cycle start date"
          : "Pick the cycle end date",

      cancelText: "Cancel",

      confirmText: "Next",

      locale: const Locale("ar"),
    );

    if (date == null) {
      return;
    }

    if (!mounted) return;

    // ==========================================================
    // INITIAL TIME
    // ==========================================================

    final oldDate =
        start
            ? startDate
            : endDate;

    TimeOfDay initialTime;

    if (oldDate != null) {
      initialTime = TimeOfDay(
        hour: oldDate.hour,
        minute: oldDate.minute,
      );
    } else if (!start &&
        startDate != null) {
      initialTime = TimeOfDay(
        hour: startDate!.hour,
        minute: startDate!.minute,
      );
    } else {
      initialTime = TimeOfDay(
        hour: now.hour,
        minute: now.minute,
      );
    }

    // ==========================================================
    // TIME PICKER
    // ==========================================================

    final time = await showTimePicker(
      context: context,

      initialTime: initialTime,

      helpText: start
          ? "Pick the cycle start time"
          : "Pick the cycle end time",

      cancelText: "Cancel",

      confirmText: "Select",

      hourLabelText: "Hour",

      minuteLabelText: "Minute",

      builder: (context, child) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (time == null) {
      return;
    }

    // ==========================================================
    // COMBINE DATE + TIME
    // ==========================================================

    final selectedDateTime =
        DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // ==========================================================
    // START DATE
    // ==========================================================

    if (start) {
      if (endDate != null &&
          endDate!.isBefore(
            selectedDateTime,
          )) {
        showMessage(
          "The cycle cannot start after it ends.",
          color: Colors.red,
        );

        return;
      }

      setState(() {
        startDate =
            selectedDateTime;
      });

      return;
    }

    // ==========================================================
    // END DATE
    // ==========================================================

    if (startDate != null &&
        selectedDateTime.isBefore(
          startDate!,
        )) {
      showMessage(
        "The cycle cannot end before it starts.",
        color: Colors.red,
      );

      return;
    }

    setState(() {
      endDate =
          selectedDateTime;
    });
  }

  // ============================================================
  // FORMAT DATE + TIME
  // ============================================================

  String _formatDateTime(
    DateTime date,
  ) {
    final year =
        date.year.toString();

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final hour24 =
        date.hour;

    final minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final period =
        hour24 >= 12
            ? "PM"
            : "AM";

    int hour12 =
        hour24 % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    return "$year-$month-$day | "
        "${hour12.toString().padLeft(2, '0')}:"
        "$minute $period";
  }

  // ============================================================
  // DATE CARD
  // ============================================================

  Widget buildDateCard({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final text = date == null
        ? "Not selected"
        : _formatDateTime(date);

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: appColor,
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 5,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  date == null
                      ? FontWeight.normal
                      : FontWeight.bold,
              color:
                  date == null
                      ? Colors.grey
                      : appColor,
            ),
          ),
        ),

        trailing: const Icon(
          Icons.calendar_month,
          color: appColor,
        ),

        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // NEXT CYCLE NUMBER
  // ============================================================

  Future<int> getNextCycleNumber() async {
    final result = await firestore
        .collection("cycles")
        .orderBy(
          "cycleNumber",
          descending: true,
        )
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      return 1;
    }

    final value =
        result.docs.first
            .data()["cycleNumber"];

    if (value is num) {
      return value.toInt() + 1;
    }

    return 1;
  }

  // ============================================================
  // SAVE CYCLE
  // ============================================================

  Future<void> saveCycle() async {
    if (_isSaving) return;

    final reading =
        normalizeMeterNumber(
      readingController.text.trim(),
    );

    // ==========================================================
    // READING
    //
    // الإدخال اليدوي يقبل أي عدد من الأرقام.
    // ==========================================================

    if (!isValidReading(reading)) {
      showMessage(
        "أدخل قراءة بداية الدور بشكل صحيح.\n"
        "Must contain one digit or more.",
        color: Colors.red,
      );

      return;
    }

    // ==========================================================
    // WELL
    // ==========================================================

    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      showMessage(
        "No well selected",
        color: Colors.orange,
      );

      return;
    }

    // ==========================================================
    // METER TYPE
    // ==========================================================

    if (meterTypeId.isEmpty) {
      showMessage(
        "Choose the meter type for this well",
        color: Colors.orange,
      );

      return;
    }

    // ==========================================================
    // PRICE
    // ==========================================================

    if (unitPrice <= 0) {
      showMessage(
        "Unit price is not set",
        color: Colors.orange,
      );

      return;
    }

    // ==========================================================
    // START DATE
    // ==========================================================

    if (startDate == null) {
      showMessage(
        "Choose the cycle start with the time",
        color: Colors.orange,
      );

      return;
    }

    // ==========================================================
    // END DATE
    // ==========================================================

    if (endDate == null) {
      showMessage(
        "Choose the cycle end with the time",
        color: Colors.orange,
      );

      return;
    }

    // ==========================================================
    // DATE VALIDATION
    // ==========================================================

    if (endDate!.isBefore(
      startDate!,
    )) {
      showMessage(
        "The end date and time cannot be before the start",
        color: Colors.red,
      );

      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      _isSaving = true;
    });

    try {
      // ========================================================
      // CHECK OPEN CYCLE
      // ========================================================

      final customerCycles =
          await firestore
              .collection("cycles")
              .where(
                "customerId",
                isEqualTo: customerId,
              )
              .get();

      final hasOpen =
          customerCycles.docs.any(
        (doc) {
          final status =
              doc.data()["status"]
                  ?.toString()
                  .trim();

          return status == "Open" ||
              status == "open";
        },
      );

      if (hasOpen) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }

        showMessage(
          "This subscriber already has an open cycle",
          color: Colors.orange,
        );

        return;
      }

      // ========================================================
      // NEXT CYCLE
      // ========================================================

      final next =
          await getNextCycleNumber();

      // ========================================================
      // READING INTEGER
      // ========================================================

      final previousValue =
          int.tryParse(reading) ?? 0;

      // ========================================================
      // CYCLE DOCUMENT
      // ========================================================

      final cycleRef =
          await firestore
              .collection("cycles")
              .add({
        // ------------------------------------------------------
        // CYCLE
        // ------------------------------------------------------

        "cycleNumber": next,

        "status": "Open",

        // ------------------------------------------------------
        // CUSTOMER
        // ------------------------------------------------------

        "customerId":
            customerId,

        "customerName":
            customerName,

        "customerPhone":
            customerPhone,

        "customerAddress":
            customerAddress,

        "accountId":
            accountId,

        // ------------------------------------------------------
        // WATER
        // ------------------------------------------------------

        "waterUsageTypeId":
            waterUsageTypeId,

        "waterUsageTypeName":
            waterUsageTypeName,

        // ------------------------------------------------------
        // METER
        // ------------------------------------------------------

        "meterTypeId":
            meterTypeId,

        "meterTypeName":
            meterTypeName,

        "unitPrice":
            unitPrice,

        // ------------------------------------------------------
        // READINGS
        // ------------------------------------------------------

        "previousReading":
            reading,

        "previousReadingValue":
            previousValue,

        "currentReading":
            "0",

        "currentReadingValue":
            0,

        "consumption":
            0,

        "amount":
            0,

        // ------------------------------------------------------
        // SUPERVISOR
        // ------------------------------------------------------

        "supervisorId":
            widget.supervisorId,

        // ------------------------------------------------------
        // LOCATION
        // ------------------------------------------------------

        "provinceId":
            widget.provinceId,

        "provinceName":
            widget.provinceName,

        "districtId":
            widget.districtId,

        "districtName":
            widget.districtName,

        "hamletId":
            widget.hamletId,

        "hamletName":
            widget.hamletName,

        "villageId":
            widget.villageId,

        "villageName":
            widget.villageName,

        "wellId":
            widget.wellId,

        "wellName":
            widget.wellName,

        // ------------------------------------------------------
        // DATES + TIMES
        // ------------------------------------------------------

        "startDate":
            Timestamp.fromDate(
          startDate!,
        ),

        "endDate":
            Timestamp.fromDate(
          endDate!,
        ),

        // ------------------------------------------------------
        // TIMESTAMPS
        // ------------------------------------------------------

        "createdAt":
            FieldValue.serverTimestamp(),

        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      // ========================================================
      // UPDATE CUSTOMER
      // ========================================================

      await firestore
          .collection("customers")
          .doc(customerId)
          .update({
        "cycleNumber":
            next,

        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) return;

      setState(() {
        _isSaving = false;

        cycleNumber = next;

        previousReading =
            reading;
      });

      showMessage(
        "Cycle opened: no. $next",
        color: Colors.green,
      );

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        cycleRef.id,
      );
    } catch (e, stackTrace) {
      debugPrint(
        "SAVE CYCLE ERROR: $e",
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      showMessage(
        "فشل حفظ الدور:\n$e",
        color: Colors.red,
      );
    }
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget buildSaveButton() {
    return Container(
      padding:
          const EdgeInsets.all(16),
      color: backgroundColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child:
              ElevatedButton.icon(
            onPressed:
                (_isSaving ||
                        _isLoadingOcr)
                    ? null
                    : saveCycle,
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  appColor,
              foregroundColor:
                  Colors.white,
              disabledBackgroundColor:
                  appColor.withValues(alpha: .5),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.lock_open,
                  ),
            label: Text(
              _isSaving
                  ? "Opening the cycle…"
                  : "Open the cycle and save",
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            backgroundColor,

        appBar: const MyAppBar(
          title: "Open a new water cycle",
        ),

        body: Column(
          children: [
            buildLocationTitleBar(),

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  children: [
                    // ------------------------------------------------
                    // CUSTOMER
                    // ------------------------------------------------

                    buildCustomerCard(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ------------------------------------------------
                    // METER TYPE
                    // ------------------------------------------------

                    buildMeterTypeSelector(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ------------------------------------------------
                    // PRICE
                    // ------------------------------------------------

                    buildPriceCard(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ------------------------------------------------
                    // READING SUMMARY
                    // ------------------------------------------------

                    buildReadingCard(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ------------------------------------------------
                    // READING
                    // ------------------------------------------------

                    buildReadingTabs(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ------------------------------------------------
                    // SELECTED READING
                    // ------------------------------------------------

                    buildSelectedReading(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ------------------------------------------------
                    // START DATE
                    // ------------------------------------------------

                    buildDateCard(
                      title:
                          "Cycle start",
                      date: startDate,
                      icon: Icons
                          .calendar_today,
                      onTap: () =>
                          selectDate(true),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // ------------------------------------------------
                    // END DATE
                    // ------------------------------------------------

                    buildDateCard(
                      title:
                          "Cycle end",
                      date: endDate,
                      icon: Icons.event,
                      onTap: () =>
                          selectDate(false),
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),

            // ------------------------------------------------------
            // SAVE
            // ------------------------------------------------------

            buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _tabController.dispose();

    readingController.dispose();

    super.dispose();
  }
}

