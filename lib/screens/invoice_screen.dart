import 'package:flutter/material.dart';


class InvoiceScreen extends StatefulWidget {

  const InvoiceScreen({super.key});


  @override
  State<InvoiceScreen> createState() =>
      _InvoiceScreenState();

}



class _InvoiceScreenState
    extends State<InvoiceScreen> {


  String? selectedCycle;


  final List<Map<String,dynamic>> invoices = [

    {
      "customer":"محمد أحمد",
      "account":"100001",
      "consumption":50,
      "price":10,
      "amount":500,
      "status":"جاهز"
    },


    {
      "customer":"أحمد علي",
      "account":"100002",
      "consumption":80,
      "price":10,
      "amount":800,
      "status":"جاهز"
    },

  ];



  final List<String> cycles=[

    "دور شهر 7 - 2026",
    "دور شهر 8 - 2026",

  ];





  void createInvoices(){


    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(

        content:
        Text(
          "تم إصدار الفواتير",
        ),

      ),

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
              "إصدار الفواتير"
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


                decoration:
                const InputDecoration(

                  labelText:
                  "اختيار الدور",

                  border:
                  OutlineInputBorder(),

                ),



                value:
                selectedCycle,



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



              const SizedBox(height:20),




              Expanded(

                child:
                ListView.builder(

                  itemCount:
                  invoices.length,


                  itemBuilder:
                      (context,index){


                    final item =
                    invoices[index];



                    return Card(

                      elevation:4,


                      child:
                      ListTile(


                        title:
                        Text(

                          item["customer"],

                          style:
                          const TextStyle(

                            fontWeight:
                            FontWeight.bold,

                          ),

                        ),



                        subtitle:
                        Text(

"""
رقم الحساب: ${item["account"]}

الاستهلاك: ${item["consumption"]}

سعر الوحدة: ${item["price"]}

قيمة الفاتورة: ${item["amount"]}
""",

                        ),



                        trailing:
                        const Icon(
                            Icons.receipt
                        ),



                      ),


                    );


                  },

                ),

              ),





              SizedBox(

                width:
                double.infinity,


                child:
                ElevatedButton.icon(

                  onPressed:
                  createInvoices,


                  icon:
                  const Icon(
                      Icons.print
                  ),


                  label:
                  const Text(
                      "إصدار الفواتير"
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