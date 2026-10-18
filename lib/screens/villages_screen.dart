import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class VillagesScreen extends StatefulWidget {

  const VillagesScreen({super.key});


  @override
  State<VillagesScreen> createState() =>
      _VillagesScreenState();

}



class _VillagesScreenState
    extends State<VillagesScreen> {


  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;


  final TextEditingController villageController =
      TextEditingController();



  String? provinceId;
  String? provinceName;


  String? districtId;
  String? districtName;


  String? hamletId;
  String? hamletName;


  bool loading = false;



  Future<void> addVillage() async {


    String name =
        villageController.text.trim();



    if (provinceId == null) {

      showMessage("اختر المحافظة");
      return;

    }


    if (districtId == null) {

      showMessage("اختر المديرية");
      return;

    }


    if (hamletId == null) {

      showMessage("اختر العزلة");
      return;

    }


    if (name.isEmpty) {

      showMessage("أدخل اسم القرية");
      return;

    }



    setState(() {

      loading = true;

    });



    await firestore.collection("villages").add({


      "name": name,


      "provinceId": provinceId,

      "provinceName": provinceName,


      "districtId": districtId,

      "districtName": districtName,


      "hamletId": hamletId,

      "hamletName": hamletName,


      "createdAt":
          FieldValue.serverTimestamp(),


    });



    villageController.clear();



    setState(() {

      loading = false;

    });



    showMessage("تمت إضافة القرية");

  }



  void showMessage(String text) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(text),
      ),

    );

  }



  @override
  void dispose() {

    villageController.dispose();

    super.dispose();

  }



  @override
  Widget build(BuildContext context) {


    return Directionality(

      textDirection:
          TextDirection.rtl,


      child: Scaffold(


        appBar: AppBar(

          title:
              const Text(
            "تهيئة القرى",
          ),

          centerTitle: true,

          backgroundColor:
              Colors.blue,

          foregroundColor:
              Colors.white,

        ),



        body:

        Padding(

          padding:
              const EdgeInsets.all(16),


          child:

          Column(

            children: [

              
              // اختيار المحافظة

              StreamBuilder<QuerySnapshot>(

                stream:
                    firestore
                    .collection("provinces")
                    .orderBy("name")
                    .snapshots(),


                builder:
                (context,snapshot){


                  if(!snapshot.hasData){

                    return const CircularProgressIndicator();

                  }



                  return DropdownButtonFormField<String>(


                    value: provinceId,


                    decoration:
                    const InputDecoration(

                      labelText:
                      "اختر المحافظة",

                      border:
                      OutlineInputBorder(),

                    ),



                    items:

                    snapshot.data!.docs.map((doc){


                      final data =
                      doc.data()
                      as Map<String,dynamic>;



                      return DropdownMenuItem<String>(


                        value:
                        doc.id,


                        child:
                        Text(
                          data["name"] ?? "",
                        ),


                      );


                    }).toList(),



                    onChanged:
                    (value){


                      final doc =
                      snapshot.data!.docs
                      .firstWhere(
                              (e)=>
                          e.id == value);



                      final data =
                      doc.data()
                      as Map<String,dynamic>;



                      provinceId =
                          value;


                      provinceName =
                          data["name"];



                      districtId = null;

                      districtName = null;


                      hamletId = null;

                      hamletName = null;



                      setState(() {});


                    },


                  );


                },

              ),



              const SizedBox(height:15),



              // هنا نكمل في الجزء الثاني:
              // المديرية
              // العزلة
              // القرية
              // العرض
              // اختيار المديرية

              if (provinceId != null)

                StreamBuilder<QuerySnapshot>(

                  stream: firestore
                      .collection("districts")
                      .where(
                        "provinceId",
                        isEqualTo: provinceId,
                      )
                      .snapshots(),


                  builder:
                      (context, snapshot) {


                    if (!snapshot.hasData) {

                      return const CircularProgressIndicator();

                    }


                    return DropdownButtonFormField<String>(

                      value: districtId,


                      decoration:
                          const InputDecoration(

                        labelText:
                            "اختر المديرية",

                        border:
                            OutlineInputBorder(),

                      ),


                      items:
                          snapshot.data!.docs.map((doc) {


                        final data =
                            doc.data()
                            as Map<String,dynamic>;


                        return DropdownMenuItem<String>(

                          value:
                              doc.id,


                          child:
                              Text(
                            data["name"] ?? "",
                          ),

                        );


                      }).toList(),


                      onChanged:
                          (value) {


                        final doc =
                            snapshot.data!.docs
                            .firstWhere(
                                (e) =>
                                    e.id ==
                                    value);


                        final data =
                            doc.data()
                            as Map<String,dynamic>;


                        districtId =
                            value;


                        districtName =
                            data["name"];


                        hamletId = null;

                        hamletName = null;


                        setState(() {});


                      },


                    );


                  },

                ),



              const SizedBox(height:15),



              // اختيار العزلة

              if (districtId != null)

                StreamBuilder<QuerySnapshot>(

                  stream: firestore
                      .collection("hamlets")
                      .where(
                        "districtId",
                        isEqualTo: districtId,
                      )
                      .snapshots(),


                  builder:
                      (context, snapshot) {


                    if (!snapshot.hasData) {

                      return const CircularProgressIndicator();

                    }


                    return DropdownButtonFormField<String>(

                      value:
                          hamletId,


                      decoration:
                          const InputDecoration(

                        labelText:
                            "اختر العزلة",

                        border:
                            OutlineInputBorder(),

                      ),


                      items:
                          snapshot.data!.docs.map((doc) {


                        final data =
                            doc.data()
                            as Map<String,dynamic>;


                        return DropdownMenuItem<String>(

                          value:
                              doc.id,


                          child:
                              Text(
                            data["name"] ?? "",
                          ),

                        );


                      }).toList(),



                      onChanged:
                          (value) {


                        final doc =
                            snapshot.data!.docs
                            .firstWhere(
                                (e) =>
                                    e.id ==
                                    value);



                        final data =
                            doc.data()
                            as Map<String,dynamic>;



                        hamletId =
                            value;


                        hamletName =
                            data["name"];


                        setState(() {});


                      },


                    );


                  },

                ),



              const SizedBox(height:15),



              // اسم القرية


              TextField(

                controller:
                    villageController,


                decoration:
                    const InputDecoration(

                  labelText:
                      "اسم القرية",

                  border:
                      OutlineInputBorder(),

                ),

              ),



              const SizedBox(height:15),



              SizedBox(

                width:
                    double.infinity,


                height:
                    50,


                child:
                    ElevatedButton.icon(

                  onPressed:
                      loading
                          ? null
                          : addVillage,


                  icon:
                      loading

                          ? const SizedBox(

                              width:20,

                              height:20,

                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2,
                              ),

                            )

                          : const Icon(
                              Icons.save,
                            ),


                  label:
                      const Text(
                    "إضافة القرية",
                  ),

                ),

              ),



              const SizedBox(height:20),



              // عرض القرى


              Expanded(

                child:
                    StreamBuilder<QuerySnapshot>(

                  stream:
                      firestore
                          .collection("villages")
                          .orderBy("name")
                          .snapshots(),



                  builder:
                      (context, snapshot) {


                    if (!snapshot.hasData) {

                      return const Center(

                        child:
                            CircularProgressIndicator(),

                      );

                    }



                    if (snapshot.data!.docs.isEmpty) {

                      return const Center(

                        child:
                            Text(
                          "لا توجد قرى",
                        ),

                      );

                    }



                    return ListView.builder(

                      itemCount:
                          snapshot.data!.docs.length,


                      itemBuilder:
                          (context,index) {


                        final data =
                            snapshot.data!.docs[index]
                            .data()
                            as Map<String,dynamic>;



                        return Card(

                          elevation:3,


                          child:
                              ListTile(

                            leading:
                                const Icon(

                              Icons.home,

                              color:
                                  Colors.blue,

                            ),



                            title:
                                Text(
                              data["name"] ?? "",
                            ),



                            subtitle:
                                Text(

                              "${data["provinceName"] ?? ""}\n"
                              "${data["districtName"] ?? ""} - "
                              "${data["hamletName"] ?? ""}",

                            ),


                          ),

                        );


                      },

                    );


                  },

                ),

              ),


            ],

          ),

        ),

      ),

    );

  }

}