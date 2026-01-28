import 'package:flutter/material.dart';
import '../../services/admin/admin_service.dart';
import '../../services/reports/user_report_block_service.dart';
import 'package:intl/intl.dart';
import '../../models/reports/user_report_block_models.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminService _adminService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _adminService = AdminService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Administrativo'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Resumen'),
              Tab(text: 'Usuarios'),
              Tab(text: 'Reportes'),
              Tab(text: 'Finanzas'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Resumen
            _OverviewTab(adminService: _adminService),
            // Tab 2: Usuarios
            _UsersTab(adminService: _adminService),
            // Tab 3: Reportes
            const _ReportsTab(),
            // Tab 4: Finanzas
            _FinanceTab(adminService: _adminService),
          ],
        ),
      ),
    );
  }
}

// Tab 1: Resumen
class _OverviewTab extends StatelessWidget {
  final AdminService adminService;

  const _OverviewTab({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: adminService.getSystemStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final stats = snapshot.data ?? {};

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Usuarios Totales',
                          value: '${stats['total_users'] ?? 0}',
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Trabajos',
                          value: '${stats['completed_works'] ?? 0}',
                          icon: Icons.work,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Ingresos',
                          value: '\$${((stats['total_revenue'] ?? 0) as num).toStringAsFixed(2)}',
                          icon: Icons.money,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Reportes Pendientes',
                          value: '${stats['pending_reports'] ?? 0}',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Estado de Trabajos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: adminService.getWorkStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final stats = snapshot.data ?? {};

              return Column(
                children: [
                  _buildWorkStatRow(
                    'Pendiente de Pago',
                    stats['pending_payment'] as int? ?? 0,
                    Colors.orange,
                  ),
                  _buildWorkStatRow(
                    'En Camino',
                    stats['on_way'] as int? ?? 0,
                    Colors.blue,
                  ),
                  _buildWorkStatRow(
                    'En Progreso',
                    stats['in_progress'] as int? ?? 0,
                    Colors.purple,
                  ),
                  _buildWorkStatRow(
                    'Completado',
                    stats['completed'] as int? ?? 0,
                    Colors.green,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Tab 2: Usuarios
class _UsersTab extends StatefulWidget {
  final AdminService adminService;

  const _UsersTab({required this.adminService});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showBlockedUsers(context),
                  icon: const Icon(Icons.block),
                  label: const Text('Ver Bloqueados'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showActiveUsers(context),
                  icon: const Icon(Icons.people),
                  label: const Text('Activos'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.adminService.getMostReportedUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return const Center(
                  child: Text('No hay usuarios reportados'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserCard(
                    user: user,
                    adminService: widget.adminService,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBlockedUsers(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuarios Bloqueados'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: widget.adminService.getBlockedUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Text('No hay usuarios bloqueados');
            }

            return SizedBox(
              width: 300,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user['full_name'] ?? 'Usuario'),
                    subtitle: Text(user['block_reason'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        await widget.adminService
                            .unblockUser(user['id']);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showActiveUsers(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuarios Activos (Últimos 30 días)'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: widget.adminService.getActiveUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Text('No hay usuarios activos');
            }

            return SizedBox(
              width: 300,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user['full_name'] ?? 'Usuario'),
                    subtitle: Text(user['role'] ?? ''),
                    trailing: Text(
                      user['email'] ?? '',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// Tab 3: Reportes
class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  late UserReportService _reportService;

  @override
  void initState() {
    super.initState();
    _reportService = UserReportService();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showReportStats(context),
            icon: const Icon(Icons.show_chart),
            label: const Text('Ver Estadísticas'),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<UserReportModel>>(
            future: _reportService.getPendingReports(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final reports = snapshot.data ?? [];

              if (reports.isEmpty) {
                return const Center(
                  child: Text('No hay reportes pendientes'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _ReportCard(
                    report: report,
                    reportService: _reportService,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showReportStats(BuildContext context) {
    // Estadísticas de reportes por razón
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Reportes'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: AdminService().getReportsByReason(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final stats = snapshot.data ?? {};

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: stats.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key),
                            Text('${e.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// Tab 4: Finanzas
class _FinanceTab extends StatelessWidget {
  final AdminService adminService;

  const _FinanceTab({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analítica de Pagos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: adminService.getPaymentAnalytics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final analytics = snapshot.data ?? {};

              return Column(
                children: [
                  _buildFinanceRow(
                    'Procesado Total',
                    '\$${((analytics['total_processed'] ?? 0) as num).toStringAsFixed(2)}',
                  ),
                  _buildFinanceRow(
                    'Comisión Plataforma',
                    '\$${((analytics['total_platform_fee'] ?? 0) as num).toStringAsFixed(2)}',
                  ),
                  _buildFinanceRow(
                    'Pago a Técnicos',
                    '\$${((analytics['total_technician_amount'] ?? 0) as num).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildFinanceRow(
                    'Pagos Exitosos',
                    '${analytics['successful_payments'] ?? 0}',
                  ),
                  _buildFinanceRow(
                    'Pagos Fallidos',
                    '${analytics['failed_payments'] ?? 0}',
                  ),
                  _buildFinanceRow(
                    'Tasa de Éxito',
                    '${((analytics['success_rate'] ?? 0) as num).toStringAsFixed(1)}%',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Ingresos por Período',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: adminService.getRevenueByPeriod(days: 30),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final revenueData = snapshot.data ?? [];

              if (revenueData.isEmpty) {
                return const Center(child: Text('Sin datos'));
              }

              return Column(
                children: revenueData
                    .map((item) => _buildFinanceRow(
                          item['date'] as String,
                          '\$${((item['revenue'] ?? 0) as num).toStringAsFixed(2)} (${item['transactions']} tx)',
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Widgets auxiliares

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final AdminService adminService;

  const _UserCard({
    required this.user,
    required this.adminService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${user['user']?['full_name'] ?? 'Usuario'} (${user['count']} reportes)'),
        subtitle: Text(user['user']?['email'] ?? ''),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'block') {
              _blockUser(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'block',
              child: Text('Bloquear usuario'),
            ),
          ],
        ),
      ),
    );
  }

  void _blockUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear Usuario'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Razón del bloqueo',
          ),
          onChanged: (reason) {
            // Guardar razón
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Bloquear usuario
              Navigator.pop(context);
            },
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final UserReportModel report;
  final UserReportService reportService;

  const _ReportCard({
    required this.report,
    required this.reportService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.reason.name.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(report.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await reportService.resolveReport(
                        report.id,
                        status: 'resolved',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Resolver'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await reportService.resolveReport(
                        report.id,
                        status: 'dismissed',
                      );
                    },
                    child: const Text('Descartar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
