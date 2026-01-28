import 'package:flutter/material.dart';
import '../../services/notifications/notification_service.dart';
import '../../models/notifications/notification_model.dart';
import '../../core/supabase_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationService _notificationService;
  late String _userId;
  NotificationType? _selectedType;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _userId = supabaseClient.auth.currentUser!.id;
  }

  String _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.paymentReceived:
        return '💰';
      case NotificationType.paymentSent:
        return '💳';
      case NotificationType.quotationReceived:
        return '📋';
      case NotificationType.quotationAccepted:
        return '✅';
      case NotificationType.quotationRejected:
        return '❌';
      case NotificationType.workStarted:
        return '🚀';
      case NotificationType.workCompleted:
        return '🏁';
      case NotificationType.messageReceived:
        return '💬';
      case NotificationType.ratingReceived:
        return '⭐';
      case NotificationType.newRequest:
        return '🆕';
      case NotificationType.workCancelled:
        return '🚫';
      case NotificationType.paymentRefunded:
        return '🔄';
    }
  }

  String _getNotificationTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.paymentReceived:
        return 'Pago Recibido';
      case NotificationType.paymentSent:
        return 'Pago Enviado';
      case NotificationType.quotationReceived:
        return 'Cotización Recibida';
      case NotificationType.quotationAccepted:
        return 'Cotización Aceptada';
      case NotificationType.quotationRejected:
        return 'Cotización Rechazada';
      case NotificationType.workStarted:
        return 'Trabajo Iniciado';
      case NotificationType.workCompleted:
        return 'Trabajo Completado';
      case NotificationType.messageReceived:
        return 'Mensaje Recibido';
      case NotificationType.ratingReceived:
        return 'Calificación Recibida';
      case NotificationType.newRequest:
        return 'Nueva Solicitud';
      case NotificationType.workCancelled:
        return 'Trabajo Cancelado';
      case NotificationType.paymentRefunded:
        return 'Pago Reembolsado';
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead(_userId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        elevation: 0,
        actions: [
          if (!_showUnreadOnly)
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'mark_all') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'mark_all',
                  child: Text('Marcar todas como leídas'),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Text('Eliminar todas'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Filtro por tipo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todas'),
                        selected: _selectedType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? null : _selectedType;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...NotificationType.values.map((type) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: FilterChip(
                            label: Text(_getNotificationTypeLabel(type)),
                            selected: _selectedType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = selected ? type : null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Filtro de no leídas
                CheckboxListTile(
                  title: const Text('Solo no leídas'),
                  value: _showUnreadOnly,
                  onChanged: (value) {
                    setState(() {
                      _showUnreadOnly = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          // Lista de notificaciones
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.listenToNotifications(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                var notifications = snapshot.data ?? [];

                // Aplicar filtros
                if (_selectedType != null) {
                  notifications = notifications
                      .where((n) => n.type == _selectedType)
                      .toList();
                }

                if (_showUnreadOnly) {
                  notifications =
                      notifications.where((n) => !n.isRead).toList();
                }

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay notificaciones',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return NotificationTile(
                      notification: notification,
                      icon: _getNotificationIcon(notification.type),
                      onMarkAsRead: () => _markAsRead(notification.id),
                      onDelete: () => _deleteNotification(notification.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todas las notificaciones'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar todas las notificaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _notificationService.deleteAllNotifications(_userId);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String icon;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.icon,
    required this.onMarkAsRead,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 24)),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'read') {
              onMarkAsRead();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'read',
              child: Text(notification.isRead
                  ? 'Marcar como no leída'
                  : 'Marcar como leída'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Eliminar'),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays} d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
