import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/profile_service.dart';

const _c0  = Color(0xFF060D28);
const _c1  = Color(0xFF0E2260);
const _c2  = Color(0xFF1F4BD5);
const _c3  = Color(0xFF6C3FE8);
const _bg  = Color(0xFFF2F5FF);
const _txt = Color(0xFF212121);
const _sub = Color(0xFF757575);
const _grn1 = Color(0xFF054F3A);
const _grn2 = Color(0xFF0FBB84);
const _sg0 = Color(0xFF012B1E);
const _sg1 = Color(0xFF054F3A);
const _sg2 = Color(0xFF0A7A56);
const _sg3 = Color(0xFF0FBB84);

class _Tap extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
  const _Tap({required this.child, required this.onTap});
  @override State<_Tap> createState() => _TapS();
}
class _TapS extends State<_Tap> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200));
  late final _s = Tween<double>(begin: 1.0, end: 0.95)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp:   (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(animation: _s,
      builder: (_, ch) => Transform.scale(scale: _s.value, child: ch),
      child: widget.child),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  final String role;
  final Map<String, dynamic>? profileData;
  const EditProfileScreen({super.key, this.role = 'shop_owner', this.profileData});
  @override State<EditProfileScreen> createState() => _EPS();
}

class _EPS extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bizCtrl;
  late final TextEditingController _addrCtrl;
  late final TextEditingController _areaCtrl;
  bool _saving = false;

  bool get _isSH => widget.role == 'stockholder';
  List<Color> get _grad => _isSH
      ? const [_sg0, _sg1, _sg2, _sg3]
      : const [_c0, _c1, _c2, _c3];

  late final _fadeC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    _fadeC.forward();
    final p    = widget.profileData;
    final prof = (p?['profile'] as Map?) ?? {};
    _nameCtrl = TextEditingController(text: (p?['name'] as String?) ?? '');
    _bizCtrl  = TextEditingController(text: _isSH
        ? (prof['company_name'] as String?) ?? ''
        : (prof['shop_name']    as String?) ?? '');
    _addrCtrl = TextEditingController(text: _isSH
        ? (prof['warehouse_address'] as String?) ?? ''
        : (prof['shop_address']      as String?) ?? '');
    _areaCtrl = TextEditingController(text: (prof['area'] as String?) ?? '');
    for (final c in [_nameCtrl, _bizCtrl, _addrCtrl, _areaCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _bizCtrl.dispose();
    _addrCtrl.dispose(); _areaCtrl.dispose();
    _fadeC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _err('Name cannot be empty'); return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final data = <String, dynamic>{'name': _nameCtrl.text.trim()};
    if (_isSH) {
      data['company_name']       = _bizCtrl.text.trim();
      data['warehouse_address']  = _addrCtrl.text.trim();
      data['area']               = _areaCtrl.text.trim();
    } else {
      data['shop_name']    = _bizCtrl.text.trim();
      data['shop_address'] = _addrCtrl.text.trim();
      data['area']         = _areaCtrl.text.trim();
    }
    final res = await ProfileService.updateProfile(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.ok) { _err(res.error ?? 'Failed to save'); return; }
    HapticFeedback.heavyImpact();
    if (mounted) Navigator.pop(context, true);
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF7B1C1C),
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))));

  String _initials() {
    final t = _nameCtrl.text.trim();
    final parts = t.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isEmpty ? '?' : parts[0][0].toUpperCase();
  }

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeC, curve: Curves.easeOut),
        child: Column(children: [
          _header(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _fieldLabel('Full Name'),
              _field(_nameCtrl, hint: 'Your full name'),
              const SizedBox(height: 16),
              _fieldLabel(_isSH ? 'Company Name' : 'Shop Name'),
              _field(_bizCtrl,  hint: _isSH ? 'e.g. Khan Wholesale Ltd' : 'e.g. Al-Amin Grocery'),
              const SizedBox(height: 16),
              _fieldLabel(_isSH ? 'Warehouse Address' : 'Shop Address'),
              _field(_addrCtrl, hint: 'Street address', lines: 2),
              const SizedBox(height: 16),
              _fieldLabel('Area / Locality'),
              _field(_areaCtrl, hint: 'e.g. Mirpur, Dhaka'),
              const SizedBox(height: 32),
              _saveBtn(),
            ]),
          )),
        ]),
      ),
    ),
  );

  // ── gradient header ───────────────────────────────────────────────────────
  Widget _header() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: _grad,
          stops: const [0.0, 0.35, 0.72, 1.0],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
    ),
    child: SafeArea(bottom: false,
      child: Stack(children: [
        Positioned(top: -20, right: -30, child: _blob(130, Colors.white, .04)),
        Positioned(top: 8,   right: 50,  child: _blob(44,  _c2, .3)),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // top bar
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: _Tap(onTap: () => Navigator.pop(context),
                    child: Container(width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 17)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Edit Profile', style: TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                SizedBox(height: 2),
                Text('Update your information',
                    style: TextStyle(color: Colors.white54, fontSize: 12.5)),
              ])),
            ]),
            const SizedBox(height: 20),
            // avatar preview
            Center(child: AnimatedBuilder(
              animation: _nameCtrl,
              builder: (_, __) => Container(width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.35), width: 2.5),
                ),
                child: Center(child: Text(_initials(),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 26, fontWeight: FontWeight.w900)))),
            )),
          ]),
        ),
      ]),
    ),
  );

  // ── field label ───────────────────────────────────────────────────────────
  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(t, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w800, color: _txt)),
  );

  // ── text field ────────────────────────────────────────────────────────────
  Widget _field(TextEditingController c, {String hint = '', int lines = 1}) =>
    TextField(
      controller: c,
      maxLines: lines,
      style: const TextStyle(fontSize: 14.5, color: _txt, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBC0D4), fontSize: 14),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E8F5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _c2.withOpacity(.5), width: 1.5)),
      ),
    );

  // ── save button ───────────────────────────────────────────────────────────
  Widget _saveBtn() => _Tap(
    onTap: _saving ? () {} : _save,
    child: Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _isSH
            ? [_sg1, _sg2, _sg3] : [_c0, _c2, _c3],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: (_isSH ? _grn2 : _c2).withOpacity(.4),
            blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Align(alignment: Alignment.topCenter,
            child: FractionallySizedBox(heightFactor: .45, widthFactor: 1,
              child: Container(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(.2), Colors.transparent]))))))),
        Center(child: _saving
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Save Changes', style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .2)),
              ])),
      ]),
    ),
  );

  Widget _blob(double sz, Color c, double op) =>
      Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(op)));
}
