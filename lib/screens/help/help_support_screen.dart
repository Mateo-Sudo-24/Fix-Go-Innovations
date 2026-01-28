import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de Help & Support que redirige a página Netlify
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // URL de la página de Help en Netlify (reemplaza con tu URL real)
  static const String helpPageUrl =
      'https://fixgoinnovations.netlify.app/help';

  Future<void> _launchHelpPage() async {
    try {
      if (await canLaunchUrl(Uri.parse(helpPageUrl))) {
        await launchUrl(
          Uri.parse(helpPageUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la página de ayuda'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y Soporte'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Centro de Ayuda',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encuentra respuestas a tus preguntas frecuentes',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Card con opciones
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opciones de Ayuda',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildHelpOption(
                      icon: Icons.school_outlined,
                      title: 'Tutoriales',
                      description: 'Aprende a usar Fix&Go Innovations',
                      onTap: _launchHelpPage,
                    ),
                    const Divider(),
                    _buildHelpOption(
                      icon: Icons.question_answer_outlined,
                      title: 'Preguntas Frecuentes (FAQ)',
                      description: 'Respuestas a preguntas comunes',
                      onTap: _launchHelpPage,
                    ),
                    const Divider(),
                    _buildHelpOption(
                      icon: Icons.description_outlined,
                      title: 'Términos y Condiciones',
                      description: 'Lee nuestros términos de servicio',
                      onTap: _launchHelpPage,
                    ),
                    const Divider(),
                    _buildHelpOption(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Política de Privacidad',
                      description: 'Cómo protegemos tus datos',
                      onTap: _launchHelpPage,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contacto directo
            Card(
              elevation: 2,
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacto Directo',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildContactOption(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: 'soporte@fixgoinnovations.com',
                      onTap: () => _launchUrl(
                          'mailto:soporte@fixgoinnovations.com'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactOption(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: '+57 (1) 800-0000',
                      onTap: () =>
                          _launchUrl('tel:+5718000000'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactOption(
                      icon: Icons.language_outlined,
                      label: 'Sitio Web',
                      value: 'www.fixgoinnovations.com',
                      onTap: _launchHelpPage,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Ir al Centro de Ayuda'),
                onPressed: _launchHelpPage,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Tip: Consulta nuestras preguntas frecuentes para resolver rápidamente tus dudas.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context).colorScheme.primary),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.open_in_new,
              size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
