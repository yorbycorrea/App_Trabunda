import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _bannerError; // sólo visual (UI)

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final auth = AuthScope.read(context);

    setState(() {
      _bannerError = null;
      _loading = true;
    });

    final success = await auth.login(_email.text, _pass.text);

    if (!mounted) return;

    if (success) {
      setState(() => _loading = false);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      setState(() {
        _loading = false;
        _bannerError = 'Credenciales incorrectas. Verifica tu correo y contraseña.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // FONDO con olas marinas (CustomPainter)
          CustomPaint(
            painter: _WavesPainter(),
            size: Size(size.width, size.height),
          ),

          // CONTENIDO
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                const SizedBox(height: 12),
                // LOGO
                Center(
                  child: Image.asset(
                    'assets/icon/logo.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingreso de supervisores',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0E2233),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (_bannerError != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEAEA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _bannerError!,
                      style: const TextStyle(color: Color(0xFFC62828)),
                    ),
                  ),
                ],

                // CARD DEL FORM
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa tu email';
                              }
                              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
                              return ok ? null : 'Email no válido';
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Text('Entrar'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loading ? null : () {},
                            child: const Text('Olvidé mi contraseña'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // PIE (opcional)
                Center(
                  child: Text(
                    'TRABUNDA SAC• Procesos Marinos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7A8C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinta las olas marinas del fondo (gradientes + curvas)
class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Capa 1: fondo degradado
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE8F2FA), // celeste claro
          Color(0xFFF5F8FB), // casi blanco azulado
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Capa 2: ola superior
    final p1 = Path()
      ..lineTo(0, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.10,
        size.width * 0.50, size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.22,
        size.width, size.height * 0.14,
      )
      ..lineTo(size.width, 0)
      ..close();

    final paint1 = Paint()..color = const Color(0xFFD6E8F7);
    canvas.drawPath(p1, paint1);

    // Capa 3: ola media
    final p2 = Path()
      ..moveTo(0, size.height * 0.14)
      ..quadraticBezierTo(
        size.width * 0.30, size.height * 0.08,
        size.width * 0.55, size.height * 0.14,
      )
      ..quadraticBezierTo(
        size.width * 0.80, size.height * 0.20,
        size.width, size.height * 0.12,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint2 = Paint()..color = const Color(0xFFBEDAF1);
    canvas.drawPath(p2, paint2);

    // Capa 4: franja superior (branding)
    final headerH = size.height * 0.10;
    final headerRect = Rect.fromLTWH(0, 0, size.width, headerH);
    final headerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F5DAA), Color(0xFF1B81C2)],
      ).createShader(headerRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0);
    // Curva inferior del header
    final header = Path()
      ..moveTo(0, 0)
      ..lineTo(0, headerH)
      ..quadraticBezierTo(
        size.width * 0.25, headerH - 18,
        size.width * 0.50, headerH - 8,
      )
      ..quadraticBezierTo(
        size.width * 0.80, headerH + 2,
        size.width, headerH - 14,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(header, headerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
