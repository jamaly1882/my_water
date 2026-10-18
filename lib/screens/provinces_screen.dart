import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProvincesScreen extends StatefulWidget {
  const ProvincesScreen({super.key});

  @override
  State<ProvincesScreen> createState() =>
      _ProvincesScreenState();
}

class _ProvincesScreenState extends State<ProvincesScreen> {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController nameController =
      TextEditingController();

  bool loading = false;


  Future<void> addProvince() async {

    String name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("أدخل اسم المحافظة"),
        ),
      );
      return;
    }


    setState(() {
      loading = true;
    });


    await firestore.collection("provinces").add({

      "name": name,

      "createdAt":
          FieldValue.serverTimestamp(),

    });


    nameController.clear();


    setState(() {
      loading = false;
    });


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تمت إضافة المحافظة"),
      ),
    );

  }



  @override
  void dispose() {

    nameController.dispose();

    super.dispose();

  }



  @override
  Widget build(BuildContext context) {

    return Directionality(

      textDirection: TextDirection.rtl,

      child: Scaffold(

        appBar: AppBar(

          title:
              const Text("تهيئة المحافظات"),

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


              TextField(

                controller:
                    nameController,

                decoration:
                    InputDecoration(

                  labelText:
                      "اسم المحافظة",

                  prefixIcon:
                      const Icon(
                    Icons.location_city,
                  ),

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(12),

                  ),

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
                          : addProvince,


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
                    "إضافة المحافظة",
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

                          .collection(
                              "provinces")

                          .orderBy(
                              "name")

                          .snapshots(),



                  builder:
                      (context, snapshot) {


                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {

                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );

                    }



                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {

                      return const Center(

                        child:
                            Text(
                          "لا توجد محافظات",
                        ),

                      );

                    }



                    return ListView.builder(

                      itemCount:
                          snapshot.data!.docs.length,


                      itemBuilder:
                          (context, index) {


                        final doc =
                            snapshot.data!.docs[index];


                        final data =
                            doc.data()
                                as Map<String,dynamic>;



                        return Card(

                          child:
                              ListTile(

                            leading:
                                const Icon(
                              Icons.map,
                              color:
                                  Colors.blue,
                            ),


                            title:
                                Text(
                              data["name"] ?? "",
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