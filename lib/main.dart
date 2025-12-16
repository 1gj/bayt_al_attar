import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AttaraApp());
}

class AttaraApp extends StatelessWidget {
  const AttaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عطارة بيت العطار',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          secondary: const Color(0xFFD4AF37),
        ),
        textTheme: GoogleFonts.cairoTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  final pages = [
    const ShopScreen(),
    const CartPlaceholder(),
    const AdminLogin()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront), label: 'المتجر'),
          NavigationDestination(
              icon: Icon(Icons.shopping_cart), label: 'السلة'),
          NavigationDestination(
              icon: Icon(Icons.admin_panel_settings), label: 'الإدارة'),
        ],
      ),
    );
  }
}

// ==================================================
// 1. شاشة المتجر
// ==================================================
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference _productsRef =
        FirebaseDatabase.instance.ref().child('products');

    return Scaffold(
      appBar: AppBar(title: const Text("بيت العطار")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _productsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("حدث خطأ ما"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("المتجر فارغ حالياً",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final dataMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> productsList = [];

          dataMap.forEach((key, value) {
            final product = Map<String, dynamic>.from(value);
            product['id'] = key;
            productsList.add(product);
          });

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: productsList.length,
            itemBuilder: (context, index) {
              return ProductCard(data: productsList[index]);
            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProductCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetails(data: data))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: data['image'] != null &&
                        data['image'].toString().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: data['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (c, u) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (c, u, e) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                            child: Icon(Icons.image,
                                size: 40, color: Colors.grey))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'منتج',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${data['price']} د.ع",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold)),
                      Text(data['unit'] == 'kg' ? "كغم" : "قطعة",
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> data;
  const ProductDetails({super.key, required this.data});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int count = 1;
  double weight = 1.0;

  double get price => double.tryParse(widget.data['price'].toString()) ?? 0;
  bool get isKg => widget.data['unit'] == 'kg';
  double get total => isKg ? price * weight : price * count;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.data['name'] ?? '')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.white,
              child: widget.data['image'] != null
                  ? CachedNetworkImage(
                      imageUrl: widget.data['image'], fit: BoxFit.contain)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${price} د.ع",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor)),
                  Text(isKg ? "سعر الكيلو غرام الواحد" : "سعر القطعة الواحدة",
                      style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 30),
                  Text(widget.data['desc'] ?? 'لا يوجد وصف',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!)),
                    child: Column(
                      children: [
                        const Text("حدد الكمية المطلوبة",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        if (isKg)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: "1.0",
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      suffixText: "كغم",
                                      border: OutlineInputBorder()),
                                  onChanged: (v) => setState(
                                      () => weight = double.tryParse(v) ?? 0),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text("مثال: 0.250 لربع كيلو"),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                  onPressed: () => setState(() {
                                        if (count > 1) count--;
                                      }),
                                  icon: const Icon(Icons.remove)),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text("$count",
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold))),
                              IconButton.filled(
                                  onPressed: () => setState(() => count++),
                                  icon: const Icon(Icons.add)),
                            ],
                          ),
                        const SizedBox(height: 15),
                        Text("الإجمالي: ${total.toStringAsFixed(0)} د.ع",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("تمت الإضافة للسلة"),
                                backgroundColor: Colors.green));
                      },
                      child: const Text("إضافة للسلة"),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// 2. شاشة الإدارة
// ==================================================
class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});
  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _pass = TextEditingController();
  bool isAuth = false;

  @override
  Widget build(BuildContext context) {
    if (isAuth) return const AddProductScreen();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text("دخول الموظفين",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: "كلمة المرور", border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_pass.text == "123456") setState(() => isAuth = true);
                },
                child: const Text("دخول"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  final _image = TextEditingController();
  String _unit = 'piece';
  bool loading = false;

  // هذه الدالة كانت ناقصة في الرد السابق
  Future<void> _upload() async {
    if (_name.text.isEmpty || _price.text.isEmpty) return;
    setState(() => loading = true);

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("products");
      await ref.push().set({
        "name": _name.text,
        "price": double.tryParse(_price.text) ?? 0.0,
        "desc": _desc.text,
        "image": _image.text,
        "unit": _unit,
        "createdAt": DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("تم نشر المنتج بنجاح!"),
            backgroundColor: Colors.green));
        _name.clear();
        _price.clear();
        _desc.clear();
        _image.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("خطأ: $e")));
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  // هذه الدالة كانت مفقودة تماماً
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة منتج جديد")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: "اسم المنتج", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: "السعر", border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField(
                    value: _unit,
                    items: const [
                      DropdownMenuItem(value: 'piece', child: Text("قطعة/عدد")),
                      DropdownMenuItem(value: 'kg', child: Text("وزن (كيلو)"))
                    ],
                    onChanged: (v) => setState(() => _unit = v.toString()),
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                )
              ],
            ),
            const SizedBox(height: 15),
            TextField(
                controller: _image,
                decoration: const InputDecoration(
                    labelText: "رابط الصورة (URL)",
                    hintText: "https://...",
                    border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: "الوصف", border: OutlineInputBorder())),
            const SizedBox(height: 25),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white),
                    onPressed: _upload,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("نشر في التطبيق"),
                  )
          ],
        ),
      ),
    );
  }
}

// الكلاس الذي كان مفقوداً
class CartPlaceholder extends StatelessWidget {
  const CartPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text("سلة المشتريات فارغة",
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
