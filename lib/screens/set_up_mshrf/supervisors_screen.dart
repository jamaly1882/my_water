import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../widgets/my_app_bar.dart';

class SupervisorsScreen extends StatefulWidget {
  const SupervisorsScreen({super.key});

  @override
  State<SupervisorsScreen> createState() =>
      _SupervisorsScreenState();
}

class _SupervisorsScreenState extends State<SupervisorsScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  static const Color mainColor = Colors.blue;

  static const Color backgroundColor =
      Color(0xffF5F9FF);

  // ============================================================
  // Controllers
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  // ============================================================
  // الموقع
  // ============================================================

  String? provinceId;
  String? provinceName;

  String? districtId;
  String? districtName;

  String? hamletId;
  String? hamletName;

  String? villageId;
  String? villageName;

  String? wellId;
  String? wellName;

  bool loading = false;
  bool demoLoading = false;

  // ============================================================
  // توليد كلمة سر عادية للمشرفين
  // ============================================================

  String generatePassword() {
    const chars =
        "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789";

    final random = Random();

    return List.generate(
      8,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ============================================================
  // تحويل رقم الدخول إلى بريد Firebase
  // ============================================================

  String createEmail(String phone) {
    return "$phone@mywater.com";
  }

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // التحقق من الموقع المختار
  // ============================================================

  bool validateLocation() {
    if (provinceId == null ||
        provinceId!.trim().isEmpty) {
      showMessage("اختر المحافظة");
      return false;
    }

    if (districtId == null ||
        districtId!.trim().isEmpty) {
      showMessage("اختر المديرية");
      return false;
    }

    if (hamletId == null ||
        hamletId!.trim().isEmpty) {
      showMessage("اختر العزلة");
      return false;
    }

    if (villageId == null ||
        villageId!.trim().isEmpty) {
      showMessage("اختر القرية");
      return false;
    }

    if (wellId == null ||
        wellId!.trim().isEmpty) {
      showMessage("اختر البئر");
      return false;
    }

    return true;
  }

  // ============================================================
  // إنشاء مشرف عادي
  // ============================================================

  Future<void> addSupervisor() async {
    if (loading || demoLoading) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      showMessage("أدخل اسم المشرف");
      return;
    }

    if (phone.isEmpty) {
      showMessage("أدخل رقم الدخول");
      return;
    }

    if (phone.toLowerCase() == "demo") {
      showMessage(
        "اسم الدخول demo مخصص للحساب التجريبي",
      );
      return;
    }

    if (!validateLocation()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // ========================================================
      // منع تكرار رقم الدخول
      // ========================================================

      final phoneExists = await firestore
          .collection("users")
          .where(
            "phone",
            isEqualTo: phone,
          )
          .where(
            "role",
            isEqualTo: "supervisor",
          )
          .get();

      if (phoneExists.docs.isNotEmpty) {
        showMessage(
          "رقم الدخول مستخدم مسبقاً",
        );
        return;
      }

      // ========================================================
      // منع وجود أكثر من مشرف لنفس البئر
      // ========================================================

      final wellExists = await firestore
          .collection("users")
          .where(
            "role",
            isEqualTo: "supervisor",
          )
          .where(
            "wellId",
            isEqualTo: wellId,
          )
          .get();

      if (wellExists.docs.isNotEmpty) {
        showMessage(
          "يوجد مشرف مسجل لهذا البئر بالفعل",
        );
        return;
      }

      final password = generatePassword();

      final email = createEmail(phone);

      // ========================================================
      // إنشاء مستخدم عادي
      //
      // ملاحظة:
      // هذا السلوك كما في كودك الأصلي.
      // ========================================================

      final UserCredential user =
          await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = user.user;

      if (firebaseUser == null) {
        showMessage(
          "تعذر إنشاء حساب المشرف",
        );
        return;
      }

      final uid = firebaseUser.uid;

      // ========================================================
      // حفظ بيانات المشرف
      // ========================================================

      await firestore
          .collection("users")
          .doc(uid)
          .set({
        "uid": uid,
        "name": name,
        "phone": phone,
        "email": email,
        "role": "supervisor",
        "active": true,

        "provinceId": provinceId,
        "provinceName": provinceName,

        "districtId": districtId,
        "districtName": districtName,

        "hamletId": hamletId,
        "hamletName": hamletName,

        "villageId": villageId,
        "villageName": villageName,

        "wellId": wellId,
        "wellName": wellName,

        "createdAt":
            FieldValue.serverTimestamp(),
      });

      // ========================================================
      // عرض بيانات الدخول
      // ========================================================

      if (!mounted) return;

      await showLoginDialog(
        title: "تم إنشاء المشرف",
        username: phone,
        password: password,
      );

      nameController.clear();
      phoneController.clear();

      if (mounted) {
        setState(() {
          provinceId = null;
          provinceName = null;

          districtId = null;
          districtName = null;

          hamletId = null;
          hamletName = null;

          villageId = null;
          villageName = null;

          wellId = null;
          wellName = null;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        showMessage(
          "رقم الدخول مستخدم مسبقاً",
        );
      } else if (e.code == "weak-password") {
        showMessage(
          "كلمة السر ضعيفة",
        );
      } else if (e.code == "invalid-email") {
        showMessage(
          "رقم الدخول غير صالح",
        );
      } else {
        showMessage(
          e.message ??
              "حدث خطأ في إنشاء المستخدم",
        );
      }
    } catch (e) {
      showMessage(
        "حدث خطأ: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // إنشاء الحساب التجريبي
  // ============================================================

  Future<void> createDemoAccount() async {
    if (loading || demoLoading) return;

    if (!validateLocation()) {
      return;
    }

    setState(() {
      demoLoading = true;
    });

    try {
      const String demoUsername = "demo";
      const String demoPassword = "Demo@123456";
      const String demoEmail = "demo@mywater.com";

      // ========================================================
      // التأكد من عدم وجود demo في Firestore
      // ========================================================

      final existingDemo = await firestore
          .collection("users")
          .where(
            "phone",
            isEqualTo: demoUsername,
          )
          .limit(1)
          .get();

      if (existingDemo.docs.isNotEmpty) {
        showMessage(
          "الحساب التجريبي موجود مسبقاً",
        );
        return;
      }

      // ========================================================
      // التأكد من عدم وجود مشرف لهذا البئر
      // ========================================================

      final wellExists = await firestore
          .collection("users")
          .where(
            "role",
            isEqualTo: "supervisor",
          )
          .where(
            "wellId",
            isEqualTo: wellId,
          )
          .limit(1)
          .get();

      if (wellExists.docs.isNotEmpty) {
        showMessage(
          "يوجد مشرف مرتبط بهذا البئر بالفعل",
        );
        return;
      }

      // ========================================================
      // إنشاء جلسة Firebase Auth ثانية
      //
      // حتى لا يتم تسجيل خروج مدير النظام
      // ========================================================

      final FirebaseAuth secondaryAuth =
          FirebaseAuth.instanceFor(
        app: FirebaseAuth.instance.app,
      );

      UserCredential credential;

      try {
        credential = await secondaryAuth
            .createUserWithEmailAndPassword(
          email: demoEmail,
          password: demoPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == "email-already-in-use") {
          showMessage(
            "حساب demo موجود مسبقاً في Firebase Authentication",
          );
          return;
        }

        rethrow;
      }

      final User? demoUser = credential.user;

      if (demoUser == null) {
        showMessage(
          "تعذر إنشاء الحساب التجريبي",
        );
        return;
      }

      final String uid = demoUser.uid;

      // ========================================================
      // حفظ بيانات الحساب التجريبي في Firestore
      // ========================================================

      await firestore
          .collection("users")
          .doc(uid)
          .set({
        "uid": uid,

        "name": "مشرف تجريبي",
        "phone": demoUsername,
        "email": demoEmail,

        "role": "supervisor",
        "active": true,
        "isDemo": true,

        "provinceId": provinceId,
        "provinceName": provinceName,

        "districtId": districtId,
        "districtName": districtName,

        "hamletId": hamletId,
        "hamletName": hamletName,

        "villageId": villageId,
        "villageName": villageName,

        "wellId": wellId,
        "wellName": wellName,

        "createdAt":
            FieldValue.serverTimestamp(),
      });

      // ========================================================
      // تسجيل خروج جلسة demo الثانية فقط
      // ========================================================

      await secondaryAuth.signOut();

      // ========================================================
      // عرض بيانات الحساب
      // ========================================================

      if (!mounted) return;

      await showLoginDialog(
        title: "تم إنشاء الحساب التجريبي",
        username: demoUsername,
        password: demoPassword,
        demo: true,
      );
    } on FirebaseAuthException catch (e) {
      showMessage(
        e.message ??
            "حدث خطأ في إنشاء الحساب التجريبي",
      );
    } catch (e) {
      showMessage(
        "حدث خطأ: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          demoLoading = false;
        });
      }
    }
  }

  // ============================================================
  // نافذة بيانات الدخول
  // ============================================================

  Future<void> showLoginDialog({
    required String title,
    required String username,
    required String password,
    bool demo = false,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: mainColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (demo)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(12),
                    margin:
                        const EdgeInsets.only(
                      bottom: 15,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.green
                          .withOpacity(.10),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: const Text(
                      "هذا الحساب مخصص للجهة التي ستقوم بتقييم النظام.",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                const Text(
                  "بيانات تسجيل الدخول",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 15),

                // ==================================================
                // اسم المستخدم
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(
                    color:
                        mainColor.withOpacity(
                      .08,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "اسم المستخدم",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SelectableText(
                        username,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // كلمة المرور
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(
                    color:
                        mainColor.withOpacity(
                      .08,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "كلمة المرور",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SelectableText(
                        password,
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color: mainColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          "$username\n$password",
                    ),
                  );

                  if (!dialogContext.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "تم نسخ بيانات الدخول",
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.copy,
                  color: mainColor,
                ),
                label: const Text(
                  "نسخ البيانات",
                  style: TextStyle(
                    color: mainColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child:
                    const Text("إغلاق"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // المحافظة
  // ============================================================

  Widget provinces() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("provinces")
          .orderBy("name")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child:
                  CircularProgressIndicator(
                color: mainColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "حدث خطأ في تحميل المحافظات",
            style: TextStyle(
              color: Colors.red,
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text(
            "لا توجد محافظات",
            style: TextStyle(
              color: Colors.grey,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final validValue = docs.any(
          (doc) => doc.id == provinceId,
        )
            ? provinceId
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,
          decoration:
              const InputDecoration(
            labelText: "اختر المحافظة",
            border:
                OutlineInputBorder(),
            focusedBorder:
                OutlineInputBorder(
              borderSide: BorderSide(
                color: mainColor,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.map,
              color: mainColor,
            ),
          ),
          items: docs.map((doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ??
                    "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final doc = docs.firstWhere(
              (e) => e.id == value,
            );

            final data =
                doc.data()
                    as Map<String, dynamic>;

            setState(() {
              provinceId = value;
              provinceName =
                  data["name"]?.toString();

              districtId = null;
              districtName = null;

              hamletId = null;
              hamletName = null;

              villageId = null;
              villageName = null;

              wellId = null;
              wellName = null;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // المديرية
  // ============================================================

  Widget districts() {
    if (provinceId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("districts")
          .where(
            "provinceId",
            isEqualTo: provinceId,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child:
                  CircularProgressIndicator(
                color: mainColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "حدث خطأ في تحميل المديريات",
            style: TextStyle(
              color: Colors.red,
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text(
            "لا توجد مديريات لهذه المحافظة",
            style: TextStyle(
              color: Colors.grey,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final validValue = docs.any(
          (doc) => doc.id == districtId,
        )
            ? districtId
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,
          decoration:
              const InputDecoration(
            labelText: "اختر المديرية",
            border:
                OutlineInputBorder(),
            focusedBorder:
                OutlineInputBorder(
              borderSide: BorderSide(
                color: mainColor,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.location_city,
              color: mainColor,
            ),
          ),
          items: docs.map((doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ??
                    "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final doc = docs.firstWhere(
              (e) => e.id == value,
            );

            final data =
                doc.data()
                    as Map<String, dynamic>;

            setState(() {
              districtId = value;
              districtName =
                  data["name"]?.toString();

              hamletId = null;
              hamletName = null;

              villageId = null;
              villageName = null;

              wellId = null;
              wellName = null;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // العزلة
  // ============================================================

  Widget hamlets() {
    if (districtId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("hamlets")
          .where(
            "districtId",
            isEqualTo: districtId,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child:
                  CircularProgressIndicator(
                color: mainColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "حدث خطأ في تحميل العُزل",
            style: TextStyle(
              color: Colors.red,
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text(
            "لا توجد عُزل لهذه المديرية",
            style: TextStyle(
              color: Colors.grey,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final validValue = docs.any(
          (doc) => doc.id == hamletId,
        )
            ? hamletId
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,
          decoration:
              const InputDecoration(
            labelText: "اختر العزلة",
            border:
                OutlineInputBorder(),
            focusedBorder:
                OutlineInputBorder(
              borderSide: BorderSide(
                color: mainColor,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.home_work,
              color: mainColor,
            ),
          ),
          items: docs.map((doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ??
                    "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final doc = docs.firstWhere(
              (e) => e.id == value,
            );

            final data =
                doc.data()
                    as Map<String, dynamic>;

            setState(() {
              hamletId = value;
              hamletName =
                  data["name"]?.toString();

              villageId = null;
              villageName = null;

              wellId = null;
              wellName = null;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // القرية
  // ============================================================

  Widget villages() {
    if (hamletId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("villages")
          .where(
            "hamletId",
            isEqualTo: hamletId,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child:
                  CircularProgressIndicator(
                color: mainColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "حدث خطأ في تحميل القرى",
            style: TextStyle(
              color: Colors.red,
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text(
            "لا توجد قرى لهذه العزلة",
            style: TextStyle(
              color: Colors.grey,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final validValue = docs.any(
          (doc) => doc.id == villageId,
        )
            ? villageId
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,
          decoration:
              const InputDecoration(
            labelText: "اختر القرية",
            border:
                OutlineInputBorder(),
            focusedBorder:
                OutlineInputBorder(
              borderSide: BorderSide(
                color: mainColor,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.home,
              color: mainColor,
            ),
          ),
          items: docs.map((doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ??
                    "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final doc = docs.firstWhere(
              (e) => e.id == value,
            );

            final data =
                doc.data()
                    as Map<String, dynamic>;

            setState(() {
              villageId = value;
              villageName =
                  data["name"]?.toString();

              wellId = null;
              wellName = null;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // البئر
  // ============================================================

  Widget wells() {
    if (villageId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("wells")
          .where(
            "villageId",
            isEqualTo: villageId,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child:
                  CircularProgressIndicator(
                color: mainColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "حدث خطأ في تحميل الآبار",
            style: TextStyle(
              color: Colors.red,
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text(
            "لا توجد آبار لهذه القرية",
            style: TextStyle(
              color: Colors.grey,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final validValue = docs.any(
          (doc) => doc.id == wellId,
        )
            ? wellId
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,
          decoration:
              const InputDecoration(
            labelText: "اختر البئر",
            border:
                OutlineInputBorder(),
            focusedBorder:
                OutlineInputBorder(
              borderSide: BorderSide(
                color: mainColor,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.water_drop,
              color: mainColor,
            ),
          ),
          items: docs.map((doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ??
                    "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final doc = docs.firstWhere(
              (e) => e.id == value,
            );

            final data =
                doc.data()
                    as Map<String, dynamic>;

            setState(() {
              wellId = value;
              wellName =
                  data["name"]?.toString();
            });
          },
        );
      },
    );
  }

  // ============================================================
  // قائمة المشرفين
  // ============================================================

  Widget supervisorsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("users")
          .where(
            "role",
            isEqualTo: "supervisor",
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: mainColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "حدث خطأ في تحميل المشرفين",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "لا توجد بيانات مشرفين",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data =
                docs[index].data()
                    as Map<String, dynamic>;

            final name =
                data["name"]?.toString() ?? "";

            final phone =
                data["phone"]?.toString() ?? "";

            final well =
                data["wellName"]?.toString() ?? "";

            final village =
                data["villageName"]?.toString() ?? "";

            final district =
                data["districtName"]?.toString() ?? "";

            final province =
                data["provinceName"]?.toString() ?? "";

            final isDemo =
                data["isDemo"] == true;

            return Card(
              elevation: 2,
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      mainColor.withOpacity(
                    .10,
                  ),
                  child: Icon(
                    isDemo
                        ? Icons
                            .verified_user
                        : Icons
                            .supervisor_account,
                    color: mainColor,
                    size: 28,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isDemo)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.green
                              .withOpacity(
                            .10,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),
                        child:
                            const Text(
                          "تجريبي",
                          style:
                              TextStyle(
                            color:
                                Colors.green,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 5,
                  ),
                  child: Text(
                    "رقم الدخول: $phone\n"
                    "المحافظة: $province\n"
                    "المديرية: $district\n"
                    "القرية: $village\n"
                    "البئر: $well",
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            backgroundColor,
        appBar: const MyAppBar(
          title: "تهيئة المشرفين",
          showBackButton: true,
        ),
        body: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            children: [
              // ==================================================
              // اسم المشرف
              // ==================================================

              TextField(
                controller:
                    nameController,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    const InputDecoration(
                  labelText:
                      "اسم المشرف",
                  border:
                      OutlineInputBorder(),
                  focusedBorder:
                      OutlineInputBorder(
                    borderSide:
                        BorderSide(
                      color:
                          mainColor,
                      width: 2,
                    ),
                  ),
                  prefixIcon:
                      Icon(
                    Icons.person,
                    color:
                        mainColor,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // رقم الدخول
              // ==================================================

              TextField(
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.text,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    const InputDecoration(
                  labelText:
                      "رقم الدخول",
                  hintText:
                      "مثال: 777123456",
                  border:
                      OutlineInputBorder(),
                  focusedBorder:
                      OutlineInputBorder(
                    borderSide:
                        BorderSide(
                      color:
                          mainColor,
                      width: 2,
                    ),
                  ),
                  prefixIcon:
                      Icon(
                    Icons.login,
                    color:
                        mainColor,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // المحافظة
              // ==================================================

              provinces(),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // المديرية
              // ==================================================

              districts(),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // العزلة
              // ==================================================

              hamlets(),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // القرية
              // ==================================================

              villages(),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // البئر
              // ==================================================

              wells(),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // حفظ المشرف العادي
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 52,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      loading ||
                              demoLoading
                          ? null
                          : addSupervisor,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        mainColor,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        mainColor
                            .withOpacity(
                      .55,
                    ),
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 3,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                  icon: loading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save,
                          color:
                              Colors.white,
                        ),
                  label: Text(
                    loading
                        ? "جاري الحفظ..."
                        : "حفظ المشرف",
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // إنشاء الحساب التجريبي
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 52,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      loading ||
                              demoLoading
                          ? null
                          : createDemoAccount,
                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        Colors.green,
                    side:
                        const BorderSide(
                      color:
                          Colors.green,
                      width: 1.5,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                  icon: demoLoading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.green,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons
                              .verified_user,
                        ),
                  label: Text(
                    demoLoading
                        ? "جاري إنشاء الحساب..."
                        : "إنشاء حساب تجريبي للتقييم",
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // عنوان القائمة
              // ==================================================

              const Align(
                alignment:
                    Alignment.centerRight,
                child: Text(
                  "المشرفون المسجلون",
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // القائمة
              // ==================================================

              Expanded(
                child:
                    supervisorsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // dispose
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();

    super.dispose();
  }
}