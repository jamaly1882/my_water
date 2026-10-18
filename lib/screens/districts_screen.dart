import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DistrictsScreen extends StatefulWidget {
  const DistrictsScreen({super.key});

  @override
  State<DistrictsScreen> createState() =>
      _DistrictsScreenState();
}

class _DistrictsScreenState extends State<DistrictsScreen> {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;


  final TextEditingController nameController =
      TextEditingController();


  String? selectedProvinceId;
  String? selectedProvinceName;


  bool loading = false;



  Future<void> addDistrict() async {


    String name =
        nameController.text.trim();



    if (selectedProvinceId == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("اختر المحافظة"),
        ),
      );

      return;

    }



    if (name.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("أدخل اسم المديرية"),
        ),
      );

      return;

    }



    setState(() {
      loading = true;
    });



    await firestore.collection("districts").add({

      "name": name,

      "provinceId":
          selectedProvinceId,

      "provinceName":
          selectedProvinceName,

      "createdAt":
          FieldValue.serverTimestamp(),

    });



    nameController.clear();


    setState(() {

      loading = false;

    });



    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(
        content:
            Text("تمت إضافة المديرية"),
      ),

    );


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
            "تهيئة المديريات",
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



              StreamBuilder<QuerySnapshot>(

                stream:
                    firestore
                        .collection("provinces")
                        .orderBy("name")
                        .snapshots(),


                builder:
                    (context, snapshot) {


                  if (!snapshot.hasData) {

                    return const CircularProgressIndicator();

                  }


                  return DropdownButtonFormField<String>(


                    value:
                        selectedProvinceId,


                    decoration:
                        const InputDecoration(

                      labelText:
                          "اختر المحافظة",

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
                          data["name"],
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



                      selectedProvinceId =
                          value;


                      selectedProvinceName =
                          data["name"];


                      setState(() {});


                    },


                  );

                },

              ),



              const SizedBox(
                height: 15,
              ),



              TextField(

                controller:
                    nameController,


                decoration:
                    const InputDecoration(

                  labelText:
                      "اسم المديرية",

                  border:
                      OutlineInputBorder(),

                ),

              ),



              const SizedBox(
                height: 15,
              ),



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
                          : addDistrict,


                  icon:
                      const Icon(
                    Icons.save,
                  ),


                  label:
                      const Text(
                    "إضافة المديرية",
                  ),

                ),

              ),



              const SizedBox(
                height: 20,
              ),



              Expanded(

                child:
                    StreamBuilder<QuerySnapshot>(

                  stream:
                      firestore
                          .collection("districts")
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



                    return ListView.builder(


                      itemCount:
                          snapshot.data!.docs.length,


                      itemBuilder:
                          (context,index){


                        final data =
                            snapshot.data!.docs[index]
                                .data()
                                as Map<String,dynamic>;



                        return Card(

                          child:
                              ListTile(

                            leading:
                                const Icon(
                              Icons.location_city,
                              color:
                                  Colors.blue,
                            ),


                            title:
                                Text(
                              data["name"] ?? "",
                            ),


                            subtitle:
                                Text(
                              data["provinceName"] ?? "",
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