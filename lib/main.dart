
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KhazntyApp());
}

const kPrimary = Color(0xFF0F766E);
const kDark = Color(0xFF0B3D3A);
const kGold = Color(0xFFF59E0B);
const kBg = Color(0xFFF6F7F4);
const kRed = Color(0xFFDC2626);

class KhazntyApp extends StatelessWidget {
  const KhazntyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خزنتي ديلي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      theme: ThemeData(primaryColor: kPrimary, colorScheme: ColorScheme.fromSeed(seedColor: kPrimary), useMaterial3: true, fontFamily: 'Cairo'),
      home: const HomeScreen(),
    );
  }
}

class Store {
  static Future<List<Map<String,dynamic>>> load(String key) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(key);
    if (s==null) return [];
    try { return List<Map<String,dynamic>>.from(jsonDecode(s)); } catch(e){ return []; }
  }
  static Future<void> save(String key, List<Map<String,dynamic>> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(data));
  }
  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeState(); }
class _HomeState extends State<HomeScreen> {
  int idx=0;
  List<Map<String,dynamic>> expenses=[], meds=[], family=[], gam3eya=[], files=[];
  bool loading=true;
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    expenses = await Store.load('expenses');
    meds = await Store.load('meds');
    family = await Store.load('family');
    gam3eya = await Store.load('gam3eya');
    files = await Store.load('files');
    if(mounted) setState(()=>loading=false);
  }
  Future<void> _refresh() async { await _load(); }
  double get monthTotal {
    final now=DateTime.now();
    return expenses.where((e){ try{ final d=DateTime.parse(e['date']??''); return d.year==now.year && d.month==now.month; }catch(_){return false;}}).fold(0.0,(s,e)=>s+ (double.tryParse('${e['amount']}')??0));
  }
  @override Widget build(BuildContext context){
    final pages=[_home(), _expensesPage(), _medsPage(), _familyPage(), _morePage()];
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('خزنتي ديلي  •  Khaznty Daily', style:TextStyle(fontWeight:FontWeight.w900)), backgroundColor: kDark, foregroundColor: Colors.white, centerTitle:true),
      body: loading ? const Center(child:CircularProgressIndicator()) : pages[idx],
      bottomNavigationBar: BottomNavigationBar(currentIndex: idx, onTap:(v){setState(()=>idx=v);}, type: BottomNavigationBarType.fixed, selectedItemColor: kPrimary, unselectedItemColor: Colors.grey, items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label:'الرئيسية'),
        BottomNavigationBarItem(icon: Icon(Icons.wallet), label:'المصاريف'),
        BottomNavigationBarItem(icon: Icon(Icons.medication), label:'الأدوية'),
        BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label:'العيلة'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label:'أكثر'),
      ]),
      floatingActionButton: idx==1 ? FloatingActionButton(onPressed: ()=>_addExpense(), backgroundColor: kPrimary, child: const Icon(Icons.add, color:Colors.white)) : idx==2 ? FloatingActionButton(onPressed: ()=>_addMed(), backgroundColor: kPrimary, child: const Icon(Icons.add, color:Colors.white)) : null,
    );
  }
  Widget _card({required String title, required String sub, required IconData icon, required Color color, VoidCallback? onTap}){
    return InkWell(onTap:onTap, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color:Colors.white, borderRadius: BorderRadius.circular(16), boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05), blurRadius:10)]), child: Row(children:[CircleAvatar(backgroundColor: color.withOpacity(0.12), radius:26, child: Icon(icon, color:color, size:28)), const SizedBox(width:12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(fontWeight:FontWeight.w900, fontSize:16)), const SizedBox(height:2), Text(sub, style: TextStyle(color:Colors.grey[600], fontSize:13))]))])));
  }
  Widget _home(){
    return ListView(padding: const EdgeInsets.all(16), children:[
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color:kDark, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        const Text('أهلاً بيك في خزنتك', style:TextStyle(color:Colors.white, fontWeight:FontWeight.w900, fontSize:22)),
        const SizedBox(height:6),
        const Text('مصاريفك وأدويتك وطوارئ عيلتك في مكان واحد، من غير ما حد يشوف بياناتك.', style:TextStyle(color:Colors.white70, fontSize:13)),
        const SizedBox(height:14),
        Row(children:[
          Expanded(child: _stat('مصاريف الشهر', '${monthTotal.toStringAsFixed(0)} ج.م', Icons.wallet)),
          const SizedBox(width:10),
          Expanded(child: _stat('أدوية', '${meds.length}', Icons.medication)),
          const SizedBox(width:10),
          Expanded(child: _stat('أفراد العيلة', '${family.length}', Icons.family_restroom)),
        ])
      ])),
      const SizedBox(height:14),
      const Text('وصول سريع', style:TextStyle(fontWeight:FontWeight.w900, fontSize:17)),
      const SizedBox(height:10),
      _card(title:'حالة طوارئ - اتصل بسرعة', sub: family.isEmpty ? 'ضيف أرقام الطوارئ من قسم العيلة' : 'عندك ${family.length} رقم طوارئ محفوظ', icon: Icons.emergency, color: kRed, onTap: ()=>setState(()=>idx=3)),
      const SizedBox(height:10),
      _card(title:'أضف مصروف جديد', sub:'مصاريف - فواتير - أقساط - دخل', icon: Icons.add_circle, color: kPrimary, onTap: ()=>setState(()=>idx=1)),
      const SizedBox(height:10),
      _card(title:'دواء اليوم', sub: meds.isEmpty ? 'لسه مفيش أدوية - ضيف أول دواء' : meds.first['name'] ?? '', icon: Icons.medication_liquid, color: Colors.orange, onTap: ()=>setState(()=>idx=2)),
      const SizedBox(height:10),
      _card(title:'الجمعية', sub: gam3eya.isEmpty ? 'تابع جمعيتك ودورك ومبلغك' : '${gam3eya.length} جمعية مسجلة', icon: Icons.groups, color: Colors.purple, onTap: ()=>setState(()=>idx=4)),
      const SizedBox(height:14),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber[200]!)), child: const Row(children:[Icon(Icons.info_outline, color: Colors.amber), SizedBox(width:8), Expanded(child: Text('خزنتي للتذكير والتنظيم فقط، وليس بديلاً عن استشارة الطبيب.', style:TextStyle(fontSize:12)))])),
    ]);
  }
  Widget _stat(String t, String v, IconData ic)=>Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color:Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Column(children:[Icon(ic, color:Colors.white, size:20), const SizedBox(height:4), Text(v, style: const TextStyle(color:Colors.white, fontWeight:FontWeight.w900)), Text(t, style: const TextStyle(color:Colors.white70, fontSize:10))]));
  // EXPENSES
  Widget _expensesPage(){
    return Column(children:[
      Padding(padding: const EdgeInsets.all(16), child: Row(children:[Expanded(child: _card(title:'إجمالي الشهر', sub:'${monthTotal.toStringAsFixed(0)} جنيه', icon: Icons.wallet, color: kPrimary)), const SizedBox(width:10), Expanded(child: _card(title:'عدد المصاريف', sub:'${expenses.length} مصروف', icon: Icons.receipt, color: Colors.blue)) ])),
      Expanded(child: expenses.isEmpty ? const Center(child: Text('لسه مفيش مصاريف\nدوس + وضيف أول مصروف', textAlign: TextAlign.center)) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal:16), itemCount: expenses.length, itemBuilder: (c,i){ final e=expenses[expenses.length-1-i]; return Card(child: ListTile(leading: CircleAvatar(child: Text('${e['category']??'م'}'.substring(0,1))), title: Text(e['title']??''), subtitle: Text('${e['category']??''} • ${e['date']??''}'), trailing: Text('${e['amount']} ج', style: const TextStyle(fontWeight:FontWeight.w900, color:kPrimary)), onLongPress: () async { expenses.remove(e); await Store.save('expenses', expenses); _refresh(); })); })),
    ]);
  }
  Future<void> _addExpense() async {
    final titleC=TextEditingController(); final amtC=TextEditingController(); String cat='مصاريف';
    final ok = await showDialog<bool>(context: context, builder:(c)=>AlertDialog(title: const Text('مصروف جديد'), content: Column(mainAxisSize: MainAxisSize.min, children:[TextField(controller: titleC, decoration: const InputDecoration(labelText:'اسم المصروف - مثال: كهربا')), TextField(controller: amtC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'المبلغ بالجنيه')), DropdownButton<String>(value:cat, isExpanded:true, items: ['مصاريف','فواتير','أقساط','دخل','أدوية','أكل','مواصلات'].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged:(v)=>cat=v!) ]), actions:[TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('إلغاء')), ElevatedButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('حفظ'))]));
    if(ok==true && titleC.text.isNotEmpty){ expenses.add({'id': const Uuid().v4(), 'title': titleC.text, 'amount': amtC.text, 'category': cat, 'date': DateTime.now().toIso8601String()}); await Store.save('expenses', expenses); _refresh(); }
  }
  // MEDS
  Widget _medsPage(){
    return Column(children:[
      const Padding(padding: EdgeInsets.all(16), child: Text('أدويتي - للتذكير فقط', style:TextStyle(fontWeight:FontWeight.w900, fontSize:18))),
      Expanded(child: meds.isEmpty ? const Center(child: Text('مفيش أدوية مسجلة\nدوس + وضيف دواء')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal:16), itemCount: meds.length, itemBuilder: (c,i){ final m=meds[i]; return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.medication, color:Colors.white)), title: Text(m['name']??''), subtitle: Text('${m['dose']??''} • ${m['time']??''} • ${m['person']??''}'), trailing: IconButton(icon: const Icon(Icons.delete, color:Colors.red), onPressed: () async { meds.removeAt(i); await Store.save('meds', meds); _refresh(); }))); })),
    ]);
  }
  Future<void> _addMed() async {
    final n=TextEditingController(); final d=TextEditingController(); final t=TextEditingController(); final p=TextEditingController();
    final ok=await showDialog<bool>(context: context, builder:(c)=>AlertDialog(title: const Text('دواء جديد'), content: Column(mainAxisSize: MainAxisSize.min, children:[TextField(controller:n, decoration: const InputDecoration(labelText:'اسم الدواء')), TextField(controller:d, decoration: const InputDecoration(labelText:'الجرعة - مثال: قرص بعد الأكل')), TextField(controller:t, decoration: const InputDecoration(labelText:'الميعاد - مثال: 9 صباحا')), TextField(controller:p, decoration: const InputDecoration(labelText:'لمين؟ - مثال: بابا'))]), actions:[TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('إلغاء')), ElevatedButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('حفظ'))]));
    if(ok==true && n.text.isNotEmpty){ meds.add({'id': const Uuid().v4(), 'name': n.text, 'dose': d.text, 'time': t.text, 'person': p.text}); await Store.save('meds', meds); _refresh(); }
  }
  // FAMILY
  Widget _familyPage(){
    return Column(children:[
      Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[200]!)), child: const Row(children:[Icon(Icons.emergency, color:kRed, size:30), SizedBox(width:10), Expanded(child: Text('في حالة الطوارئ: بياناتك هنا عشان أي حد يساعدك بسرعة.', style:TextStyle(fontWeight:FontWeight.bold)))])),
      Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: SizedBox(width:double.infinity, child: ElevatedButton.icon(onPressed: _addFamily, icon: const Icon(Icons.add), label: const Text('أضف فرد من العيلة'), style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white)))),
      const SizedBox(height:10),
      Expanded(child: family.isEmpty ? const Center(child: Text('ضيف أفراد عيلتك وأرقام الطوارئ')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal:16), itemCount: family.length, itemBuilder: (c,i){ final f=family[i]; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: kDark, child: Text((f['name']??'؟').substring(0,1), style: const TextStyle(color:Colors.white))), title: Text(f['name']??''), subtitle: Text('${f['relation']??''} • فصيلة: ${f['blood']??'-'} • حساسية: ${f['allergy']??'لا يوجد'}\n📞 ${f['phone']??''}'), isThreeLine:true, trailing: IconButton(icon: const Icon(Icons.delete, color:Colors.red), onPressed: () async { family.removeAt(i); await Store.save('family', family); _refresh(); }))); })),
    ]);
  }
  Future<void> _addFamily() async {
    final n=TextEditingController(); final r=TextEditingController(); final b=TextEditingController(); final a=TextEditingController(); final ph=TextEditingController();
    final ok=await showDialog<bool>(context: context, builder:(c)=>AlertDialog(title: const Text('فرد جديد'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children:[TextField(controller:n, decoration: const InputDecoration(labelText:'الاسم')), TextField(controller:r, decoration: const InputDecoration(labelText:'صلة القرابة - أب / أم / ابن')), TextField(controller:b, decoration: const InputDecoration(labelText:'فصيلة الدم')), TextField(controller:a, decoration: const InputDecoration(labelText:'الحساسية')), TextField(controller:ph, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText:'رقم الطوارئ'))])), actions:[TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('إلغاء')), ElevatedButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('حفظ'))]));
    if(ok==true && n.text.isNotEmpty){ family.add({'id': const Uuid().v4(), 'name': n.text, 'relation': r.text, 'blood': b.text, 'allergy': a.text, 'phone': ph.text}); await Store.save('family', family); _refresh(); }
  }
  // MORE
  Widget _morePage(){
    return ListView(padding: const EdgeInsets.all(16), children:[
      const Text('أكثر', style:TextStyle(fontWeight:FontWeight.w900, fontSize:20)),
      const SizedBox(height:12),
      _card(title:'الجمعية', sub:'${gam3eya.length} جمعية - دوس لإضافة جمعية', icon: Icons.groups, color: Colors.purple, onTap: _addGam3eya),
      const SizedBox(height:10),
      _card(title:'ملفاتي المهمة', sub:'${files.length} ملف - بطاقة - روشتة - عقد', icon: Icons.folder, color: Colors.blue, onTap: _addFile),
      const SizedBox(height:10),
      _card(title:'حذف كل بياناتي', sub:'امسح كل اللي دخلته من على موبايلك', icon: Icons.delete_forever, color: kRed, onTap: _deleteAll),
      const SizedBox(height:10),
      _card(title:'سياسة الخصوصية', sub:'بياناتك على موبايلك بس - مفيش سيرفر - مفيش تتبع', icon: Icons.privacy_tip, color: kPrimary),
      const SizedBox(height:10),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color:Colors.white, borderRadius: BorderRadius.circular(14)), child: const Text('خزنتي ديلي v1.0.0\nصُنع بحب في مصر 🇪🇬\nالتطبيق للتذكير والتنظيم فقط، وليس بديلاً عن استشارة الطبيب.', textAlign: TextAlign.center)),
    ]);
  }
  Future<void> _addGam3eya() async {
    final n=TextEditingController(); final amt=TextEditingController(); final role=TextEditingController();
    final ok=await showDialog<bool>(context: context, builder:(c)=>AlertDialog(title: const Text('جمعية جديدة'), content: Column(mainAxisSize: MainAxisSize.min, children:[TextField(controller:n, decoration: const InputDecoration(labelText:'اسم الجمعية')), TextField(controller:amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'المبلغ')), TextField(controller:role, decoration: const InputDecoration(labelText:'دورك - الشهر الكام؟'))]), actions:[TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('إلغاء')), ElevatedButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('حفظ'))]));
    if(ok==true && n.text.isNotEmpty){ gam3eya.add({'name': n.text, 'amount': amt.text, 'role': role.text}); await Store.save('gam3eya', gam3eya); _refresh(); }
  }
  Future<void> _addFile() async {
    final n=TextEditingController(); final ty=TextEditingController();
    final ok=await showDialog<bool>(context: context, builder:(c)=>AlertDialog(title: const Text('ملف جديد'), content: Column(mainAxisSize: MainAxisSize.min, children:[TextField(controller:n, decoration: const InputDecoration(labelText:'اسم الملف - مثال: بطاقة بابا')), TextField(controller:ty, decoration: const InputDecoration(labelText:'النوع - بطاقة / روشتة / عقد'))]), actions:[TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('إلغاء')), ElevatedButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('حفظ'))]));
    if(ok==true && n.text.isNotEmpty){ files.add({'name': n.text, 'type': ty.text}); await Store.save('files', files); _refresh(); }
  }
  Future<void> _deleteAll() async {
    final ok=await showDialog<bool>(context: context, builder:(c)=>AlertDialog(title: const Text('حذف كل البيانات؟'), content: const Text('هتمسح كل المصاريف والأدوية والعيلة من على موبايلك نهائياً.'), actions:[TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('إلغاء')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kRed), onPressed: ()=>Navigator.pop(c,true), child: const Text('حذف', style:TextStyle(color:Colors.white)))]));
    if(ok==true){ await Store.clearAll(); await _load(); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف كل بياناتك'))); }
  }
}
