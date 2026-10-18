import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
class CloseCycleScreen extends StatefulWidget {

  const CloseCycleScreen({super.key});


  @override
  State<CloseCycleScreen> createState() =>
      _CloseCycleScreenState();

}



class _CloseCycleScreenState
    extends State<CloseCycleScreen> {


  String? selectedCycle;


  final List<String> cycles = [

    "دور شهر 7 - 2026",
    "دور شهر 8 - 2026",

  ];



  int readingsCount = 250;

  int invoicesCount = 250;

  double totalAmount = 125000;





  void closeCycle(){


    showDialog(

      context: context,

      builder: (context){


        return AlertDialog(

          title:
          const Text(
              "تأكيد إغلاق الدور"
          ),


          content:
          const Text(

              "بعد إغلاق الدور لن يمكن تعديل القراءات والفواتير"

          ),



          actions:[


            TextButton(

              onPressed: (){

                Navigator.pop(context);

              },

              child:
              const Text(
                  "إلغاء"
              ),

            ),



            ElevatedButton(

              onPressed: (){


                Navigator.pop(context);


                ScaffoldMessenger.of(context)
                    .showSnackBar(

                  const SnackBar(

                    content:
                    Text(
                        "تم إغلاق الدور بنجاح"
                    ),

                  ),

                );


              },


              child:
              const Text(
                  "إغلاق"
              ),

            ),



          ],

        );

      },

    );


  }







  @override
  Widget build(BuildContext context) {


    return Directionality(

      textDirection:
      TextDirection.rtl,


      child: Scaffold(

        appBar:
        AppBar(

          title:
          const Text(
              "إغلاق الدور"
          ),

          centerTitle:true,

        ),



        body:
        Padding(

          padding:
          const EdgeInsets.all(16),


          child:
          Column(

            children:[



              DropdownButtonFormField<String>(


                value:
                selectedCycle,


                decoration:
                const InputDecoration(

                  labelText:
                  "اختيار الدور",

                  border:
                  OutlineInputBorder(),

                ),



                items:
                cycles.map((e){


                  return DropdownMenuItem(

                    value:e,

                    child:
                    Text(e),

                  );


                }).toList(),



                onChanged:(v){


                  setState(() {

                    selectedCycle=v;

                  });


                },

              ),





              const SizedBox(height:25),




              Card(

                child:
                ListTile(

                  leading:
                  const Icon(
                      Icons.speed
                  ),

                  title:
                  const Text(
                      "عدد القراءات"
                  ),

                  trailing:
                  Text(
                    "$readingsCount",
                    style:
                    const TextStyle(
                        fontWeight:
                        FontWeight.bold
                    ),
                  ),

                ),

              ),





              Card(

                child:
                ListTile(

                  leading:
                  const Icon(
                      Icons.receipt_long
                  ),


                  title:
                  const Text(
                      "عدد الفواتير"
                  ),


                  trailing:
                  Text(
                    "$invoicesCount",
                  ),

                ),

              ),





              Card(

                child:
                ListTile(

                  leading:
                  const Icon(
                      Icons.money
                  ),


                  title:
                  const Text(
                      "إجمالي الفواتير"
                  ),


                  trailing:
                  Text(
                    "$totalAmount",
                  ),

                ),

              ),





              const Spacer(),




              SizedBox(

                width:
                double.infinity,


                child:
                ElevatedButton.icon(

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    Colors.red,

                    foregroundColor:
                    Colors.white,

                  ),


                  onPressed:
                  closeCycle,


                  icon:
                  const Icon(
                      Icons.lock
                  ),


                  label:
                  const Text(
                      "إغلاق الدور"
                  ),


                ),

              )


            ],

          ),

        ),

      ),

    );

  }

}