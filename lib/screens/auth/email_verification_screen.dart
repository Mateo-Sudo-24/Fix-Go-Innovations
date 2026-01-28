import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isVerified = false;
  bool _showResendOption = false;
  late DateTime _verificationSentAt;

  @override
  void initState() {
    super.initState();
    _verificationSentAt = DateTime.now();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    setState(() => _isLoading = true);

    try {
      // Esperar un poco antes de verificar
      await Future.delayed(const Duration(seconds: 2));

      final session = _supabase.auth.currentSession;
      if (session != null && session.user.emailConfirmedAt != null) {
        setState(() => _isVerified = true);

        // Mostrar éxito y redirigir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email verificado correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Redirigir después de 2 segundos
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        setState(() => _isLoading = false);

        // Después de 5 minutos, mostrar opción de reenviar
        final timeDiff = DateTime.now().difference(_verificationSentAt);
        if (timeDiff.inSeconds > 300) {
          setState(() => _showResendOption = true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);

    try {
      await _supabase.auth.resetPasswordForEmail(widget.email);

      setState(() {
        _isLoading = false;
        _showResendOption = false;
        _verificationSentAt = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Email de verificación reenviado'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Esperar y verificar de nuevo
      await Future.delayed(const Duration(seconds: 2));
      _checkEmailVerification();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icono
            _isVerified
                ? Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.green[600],
                  )
                : Icon(
                    Icons.mail_outline,
                    size: 100,
                    color: Colors.blue[600],
                  ),
            const SizedBox(height: 24),

            // Título
            Text(
              _isVerified ? '✅ Email Verificado' : '📧 Verifica tu Email',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              _isVerified
                  ? 'Tu email ha sido verificado correctamente. Serás redirigido a continuación.'
                  : 'Hemos enviado un enlace de verificación a:\n\n${widget.email}\n\nRevisa tu email (incluida la carpeta de spam) y haz clic en el enlace para verificar tu cuenta.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Loading Indicator
            if (_isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    _isVerified
                        ? 'Redirigiendo...'
                        : 'Verificando tu email...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Resend Button (aparece después de 5 minutos)
            if (_showResendOption && !_isVerified)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '🔄 Reenviar Email de Verificación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (!_isVerified) const SizedBox(height: 24),

            // Back Button (solo si no está verificado)
            if (!_isVerified)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver al Login'),
              ),

            const SizedBox(height: 40),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consejos de verificación',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Revisa la carpeta de spam o correo no deseado\n'
                    '• Espera a que llegue el email (puede tomar unos minutos)\n'
                    '• El enlace es válido por 24 horas\n'
                    '• Haz clic en "Reenviar" si no recibes nada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
