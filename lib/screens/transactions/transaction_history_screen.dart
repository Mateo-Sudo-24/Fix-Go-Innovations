import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import '../../core/supabase_client.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PaymentService _paymentService;
  late String _userId;
  String _filterStatus = 'all'; // all, completed, failed, pending
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _paymentService = PaymentService();
    _userId = supabaseClient.auth.currentUser!.id;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Transacciones'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pagos Realizados'),
              Tab(text: 'Pagos Recibidos'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Pagos que realizó (cliente)
            _TransactionListWidget(
              paymentService: _paymentService,
              userId: _userId,
              type: 'sent',
              filterStatus: _filterStatus,
              dateRange: _dateRange,
              onFilterChanged: (status) =>
                  setState(() => _filterStatus = status),
              onDateRangeChanged: _pickDateRange,
            ),
            // Tab 2: Pagos que recibió (técnico)
            _TransactionListWidget(
              paymentService: _paymentService,
              userId: _userId,
              type: 'received',
              filterStatus: _filterStatus,
              dateRange: _dateRange,
              onFilterChanged: (status) =>
                  setState(() => _filterStatus = status),
              onDateRangeChanged: _pickDateRange,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionListWidget extends StatefulWidget {
  final PaymentService paymentService;
  final String userId;
  final String type; // 'sent' o 'received'
  final String filterStatus;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onDateRangeChanged;

  const _TransactionListWidget({
    Key? key,
    required this.paymentService,
    required this.userId,
    required this.type,
    required this.filterStatus,
    required this.dateRange,
    required this.onFilterChanged,
    required this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<_TransactionListWidget> createState() => _TransactionListWidgetState();
}

class _TransactionListWidgetState extends State<_TransactionListWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Filtro por estado
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completado', 'completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Fallido', 'failed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pendiente', 'pending'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Filtro por fecha
              GestureDetector(
                onTap: widget.onDateRangeChanged,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            widget.dateRange != null
                                ? '${_formatShortDate(widget.dateRange!.start)} - ${_formatShortDate(widget.dateRange!.end)}'
                                : 'Seleccionar rango',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (widget.dateRange != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => widget.onFilterChanged('all')),
                          child: const Icon(Icons.close, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de transacciones
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _getTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final transactions = snapshot.data ?? [];

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No hay transacciones'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _TransactionCard(
                    transaction: transaction,
                    type: widget.type,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = widget.filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        widget.onFilterChanged(value);
      },
    );
  }

  Future<List<dynamic>> _getTransactions() async {
    List<dynamic> transactions = [];

    try {
      if (widget.type == 'sent') {
        transactions = await widget.paymentService.getClientPayments(
          widget.userId,
        );
      } else {
        transactions = await widget.paymentService.getTechnicianPayments(
          widget.userId,
        );
      }

      // Aplicar filtros
      if (widget.filterStatus != 'all') {
        transactions = transactions
            .where((t) => _getTransactionStatus(t) == widget.filterStatus)
            .toList();
      }

      if (widget.dateRange != null) {
        transactions = transactions.where((t) {
          final date = DateTime.parse(t['created_at']);
          return date.isAfter(widget.dateRange!.start) &&
              date.isBefore(widget.dateRange!.end.add(const Duration(days: 1)));
        }).toList();
      }

      return transactions;
    } catch (e) {
      throw Exception('Error loading transactions: $e');
    }
  }

  String _getTransactionStatus(dynamic transaction) {
    final status = transaction['status'] as String? ?? 'pending';
    return status.toLowerCase();
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }
}

class _TransactionCard extends StatelessWidget {
  final dynamic transaction;
  final String type; // 'sent' o 'received'

  const _TransactionCard({
    required this.transaction,
    required this.type,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completado';
      case 'pending':
        return 'Pendiente';
      case 'failed':
        return 'Fallido';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = transaction['status'] as String? ?? 'pending';
    final amount = (transaction['amount'] as num).toDouble();
    final createdAt = DateTime.parse(transaction['created_at']);
    final platformFee = (transaction['platform_fee'] as num?)?.toDouble() ?? 0;
    final technicianAmount =
        (transaction['technician_amount'] as num?)?.toDouble() ?? 0;
    final transactionId = transaction['id'] as String? ?? '';
    final metadata = transaction['payment_metadata'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          _getStatusIcon(status),
          color: _getStatusColor(status),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'sent' ? 'Pago Enviado' : 'Pago Recibido',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
            Text(
              type == 'sent' ? '-${_formatCurrency(amount)}' : '+${_formatCurrency(technicianAmount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: type == 'sent' ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _formatDate(createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Monto Total', _formatCurrency(amount)),
                if (platformFee > 0) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Comisión Plataforma (10%)',
                    _formatCurrency(platformFee),
                  ),
                ],
                if (technicianAmount > 0) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Monto Técnico',
                    _formatCurrency(technicianAmount),
                  ),
                ],
                const SizedBox(height: 12),
                Divider(),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'ID Transacción',
                  transactionId.substring(0, 8) + '...',
                  copyable: true,
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Fecha', _formatDate(createdAt)),
                if (metadata != null) ...[
                  const SizedBox(height: 12),
                  Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Detalles Braintree',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Nonce',
                    (metadata['nonce'] as String?)?.substring(0, 10) ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  if (metadata['deviceData'] != null)
                    _buildDetailRow('Device Data', 'Incluido'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (copyable)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () {
                    // Copiar al portapapeles
                  },
                  child: const Icon(Icons.copy, size: 16, color: Colors.blue),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
