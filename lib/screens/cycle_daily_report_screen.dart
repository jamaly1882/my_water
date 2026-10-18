import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CycleDailyReportScreen extends StatelessWidget {

  const CycleDailyReportScreen({super.key});


  @override
  Widget build(BuildContext context) {


    final now = DateTime.now();


    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );


    final end = start.add(
      const Duration(days: 1),
    );



    return Directionality(

      textDirection: TextDirection.rtl,


      child: Scaffold(


        appBar: AppBar(

          title: const Text(
            "تقرير الدور اليومي",
          ),

          centerTitle: true,

        ),



        body:

        StreamBuilder<QuerySnapshot>(


          stream:

          FirebaseFirestore.instance

              .collection("cycles")

              .where(

              "createdAt",

              isGreaterThanOrEqualTo:
              Timestamp.fromDate(start)

          )

              .where(

              "createdAt",

              isLessThan:
              Timestamp.fromDate(end)

          )

              .snapshots(),





          builder:(context,snapshot){



            if(snapshot.connectionState ==
                ConnectionState.waiting){


              return const Center(

                child:
                CircularProgressIndicator(),

              );

            }





            if(!snapshot.hasData ||
                snapshot.data!.docs.isEmpty){


              return const Center(

                child:

                Text(
                  "لا يوجد أدوار اليوم",
                  style: TextStyle(
                    fontSize:18,
                  ),
                ),

              );


            }





            final docs =
                snapshot.data!.docs;





            return SingleChildScrollView(


              scrollDirection:
              Axis.horizontal,


              child:

              SingleChildScrollView(


                child:

                DataTable(



                  border:

                  TableBorder.all(),




                  columns: const [



                    DataColumn(
                      label:
                      Text("رقم الدور"),
                    ),



                    DataColumn(
                      label:
                      Text("الزبون"),
                    ),



                    DataColumn(
                      label:
                      Text("الهاتف"),
                    ),



                    DataColumn(
                      label:
                      Text("العنوان"),
                    ),



                    DataColumn(
                      label:
                      Text("الاستخدام"),
                    ),



                    DataColumn(
                      label:
                      Text("العداد"),
                    ),



                    DataColumn(
                      label:
                      Text("السعر"),
                    ),



                    DataColumn(
                      label:
                      Text("السابقة"),
                    ),



                    DataColumn(
                      label:
                      Text("الحالية"),
                    ),



                    DataColumn(
                      label:
                      Text("الاستهلاك"),
                    ),



                    DataColumn(
                      label:
                      Text("الإجمالي"),
                    ),



                    DataColumn(
                      label:
                      Text("الحالة"),
                    ),



                  ],






                  rows:

                  docs.map((doc){



                    final data =

                    doc.data()
                    as Map<String,dynamic>;





                    return DataRow(



                      cells:[



                        DataCell(

                          Text(

                            "${data["cycleNumber"] ?? 0}",

                          ),

                        ),





                        DataCell(

                          Text(

                            data["customerName"] ?? "",

                          ),

                        ),





                        DataCell(

                          Text(

                            data["customerPhone"] ?? "",

                          ),

                        ),






                        DataCell(

                          Text(

                            data["customerAddress"] ?? "",

                          ),

                        ),





                        DataCell(

                          Text(

                            data["waterUsageTypeName"] ?? "",

                          ),

                        ),






                        DataCell(

                          Text(

                            data["meterTypeName"] ?? "",

                          ),

                        ),






                        DataCell(

                          Text(

                            "${data["unitPrice"] ?? 0}",

                          ),

                        ),






                        DataCell(

                          Text(

                            "${data["previousReading"] ?? 0}",

                          ),

                        ),






                        DataCell(

                          Text(

                            "${data["currentReading"] ?? 0}",

                          ),

                        ),






                        DataCell(

                          Text(

                            "${data["consumption"] ?? 0}",

                          ),

                        ),






                        DataCell(

                          Text(

                            "${data["amount"] ?? 0}",

                          ),

                        ),






                        DataCell(

                          Text(

                            data["status"] ?? "",

                          ),

                        ),





                      ],


                    );



                  }).toList(),


                ),


              ),


            );


          },


        ),


      ),

    );


  }


}