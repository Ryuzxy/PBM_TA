import 'package:flutter/material.dart';

void main() {
  runApp(const FigmaToCodeApp());
}
class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: Scaffold(
        body: ListView(children: [
          Checkout(),
        ]),
      ),
    );
  }
}

class Checkout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375,
          height: 812,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: const Color(0xFFFDFDFD)),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 375,
                  height: 44,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 336.33,
                        top: 17.33,
                        child: Opacity(
                          opacity: 0.35,
                          child: Container(
                            width: 22,
                            height: 11.33,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(width: 1),
                                borderRadius: BorderRadius.circular(2.67),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 338.33,
                        top: 19.33,
                        child: Container(
                          width: 18,
                          height: 7.33,
                          decoration: ShapeDecoration(
                            color: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1.33),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 21,
                        top: 7,
                        child: Container(
                          width: 54,
                          height: 21,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 6,
                                child: SizedBox(
                                  width: 54,
                                  child: Text(
                                    '9:41',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w100,
                                      height: 1.33,
                                      letterSpacing: -0.24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 106,
                        child: Opacity(
                          opacity: 0.20,
                          child: Container(
                            width: 375,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  strokeAlign: BorderSide.strokeAlignCenter,
                                  color: const Color(0xFFC5C5C5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 143,
                top: 66,
                child: Text(
                  'Checkout',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    height: 1.22,
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 259,
                child: Text(
                  'Shopping List',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    height: 1.57,
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 156,
                child: Container(
                  width: 241,
                  height: 79,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                        spreadRadius: -8,
                      ),
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 9,
                        offset: Offset(0, -4),
                        spreadRadius: -7,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 34,
                top: 168,
                child: Text(
                  'Address :',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    height: 1.83,
                  ),
                ),
              ),
              Positioned(
                left: 34,
                top: 194,
                child: SizedBox(
                  width: 213,
                  height: 29,
                  child: Text(
                    "216 St Paul's Rd, London N1 2LL, UK\nContact :  +44-784232",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                      height: 1.17,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 42,
                top: 124,
                child: Text(
                  'Delivery Address',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    height: 1.57,
                  ),
                ),
              ),
              Positioned(
                left: 275,
                top: 156,
                child: Container(
                  width: 78,
                  height: 79,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                        spreadRadius: -8,
                      ),
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 9,
                        offset: Offset(0, -4),
                        spreadRadius: -7,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 291,
                child: Container(
                  width: 331,
                  height: 191,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                        spreadRadius: -8,
                      ),
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 9,
                        offset: Offset(0, -4),
                        spreadRadius: -7,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 308,
                child: Text(
                  'Women’s Casual Wear',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    height: 1.57,
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 335,
                child: Text(
                  'Variations : ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    height: 1.83,
                  ),
                ),
              ),
              Positioned(
                left: 34,
                top: 450,
                child: Text(
                  'Total Order (1)   :',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    height: 1.83,
                  ),
                ),
              ),
              Positioned(
                left: 297,
                top: 450,
                child: Text(
                  '\$ 34.00',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    height: 1.83,
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 364,
                child: SizedBox(
                  width: 19,
                  height: 16,
                  child: Text(
                    '4.8',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 1.83,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 251,
                top: 340,
                child: SizedBox(
                  width: 30,
                  height: 12,
                  child: Text(
                    'Black',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 2.20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 32,
                top: 438,
                child: Opacity(
                  opacity: 0.60,
                  child: Container(
                    width: 311,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          strokeAlign: BorderSide.strokeAlignCenter,
                          color: const Color(0xFFBBBBBB),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 181,
                top: 395,
                child: SizedBox(
                  width: 64,
                  height: 12,
                  child: Text(
                    '\$ 34.00',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      height: 1.38,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 267,
                top: 401,
                child: SizedBox(
                  width: 45,
                  height: 12,
                  child: Text(
                    '\$ 64.00',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFA6A6A6),
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 1.83,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 266,
                top: 388,
                child: SizedBox(
                  width: 53,
                  height: 12,
                  child: Text(
                    'upto 33% off  ',
                    style: TextStyle(
                      color: const Color(0xFFEA3030),
                      fontSize: 8,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 2.75,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 295,
                top: 340,
                child: SizedBox(
                  width: 30,
                  height: 12,
                  child: Text(
                    'Red',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 2.20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 32,
                top: 301,
                child: Container(
                  width: 130.53,
                  height: 125,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              Positioned(
                left: 12.09,
                top: 289.94,
                child: Container(
                  width: 168.14,
                  height: 165.93,
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/168x166"),
                      fit: BoxFit.fill,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              Positioned(
                left: 246,
                top: 338,
                child: Container(
                  width: 39,
                  height: 17,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.30,
                        color: const Color(0xFF0D0808),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 387,
                child: Container(
                  width: 84,
                  height: 29,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.30,
                        color: const Color(0xFFCACACA),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 290,
                top: 338,
                child: Container(
                  width: 39,
                  height: 17,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.30,
                        color: const Color(0xFF0D0808),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 496,
                child: Container(
                  width: 331,
                  height: 191,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                        spreadRadius: -8,
                      ),
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 9,
                        offset: Offset(0, -4),
                        spreadRadius: -7,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 513,
                child: Text(
                  'Men’s Jacket',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    height: 1.57,
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 540,
                child: Text(
                  'Variations : ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    height: 1.83,
                  ),
                ),
              ),
              Positioned(
                left: 34,
                top: 655,
                child: Text(
                  'Total Order (1)   :',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    height: 1.83,
                  ),
                ),
              ),
              Positioned(
                left: 298,
                top: 655,
                child: Text(
                  '\$ 45.00',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    height: 1.83,
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 569,
                child: SizedBox(
                  width: 19,
                  height: 16,
                  child: Text(
                    '4.7',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 1.83,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 251,
                top: 545,
                child: SizedBox(
                  width: 31,
                  height: 12,
                  child: Text(
                    'Green',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 2.20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 32,
                top: 643,
                child: Opacity(
                  opacity: 0.60,
                  child: Container(
                    width: 311,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          strokeAlign: BorderSide.strokeAlignCenter,
                          color: const Color(0xFFBBBBBB),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 181,
                top: 600,
                child: SizedBox(
                  width: 64,
                  height: 12,
                  child: Text(
                    '\$ 45.00',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      height: 1.38,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 267,
                top: 606,
                child: SizedBox(
                  width: 45,
                  height: 12,
                  child: Text(
                    '\$ 67.00',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFA6A6A6),
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 1.83,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 266,
                top: 593,
                child: SizedBox(
                  width: 53,
                  height: 12,
                  child: Text(
                    'upto 28% off  ',
                    style: TextStyle(
                      color: const Color(0xFFEA3030),
                      fontSize: 8,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 2.75,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 297,
                top: 545,
                child: SizedBox(
                  width: 32,
                  height: 12,
                  child: Text(
                    'Grey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                      height: 2.20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 32,
                top: 506,
                child: Container(
                  width: 130.53,
                  height: 125,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              Positioned(
                left: 13,
                top: 501,
                child: Container(
                  width: 159,
                  height: 156,
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/159x156"),
                      fit: BoxFit.cover,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              Positioned(
                left: 246,
                top: 543,
                child: Container(
                  width: 41,
                  height: 17,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.30,
                        color: const Color(0xFF0D0808),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 592,
                child: Container(
                  width: 84,
                  height: 29,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.30,
                        color: const Color(0xFFCACACA),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 292,
                top: 543,
                child: Container(
                  width: 41,
                  height: 17,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.30,
                        color: const Color(0xFF0D0808),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 359,
                top: 288,
                child: Container(
                  width: 6,
                  height: 431,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE8E8E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 359,
                top: 327,
                child: Container(
                  width: 6,
                  height: 179,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFBBBBBB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}