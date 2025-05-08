// lib/screens/calendar/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart';
import '../../models/lease.dart';
import '../../models/payment.dart';
import '../../models/expense.dart';
import '../../providers/lease_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/tenant_provider.dart';
import '../properties/property_detail_screen.dart';
import '../tenants/tenant_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  Calendar? _selectedCalendar;
  List<Calendar> _availableCalendars = [];
  bool _isLoading = true;
  Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _initializeCalendar();
  }

  Future<void> _initializeCalendar() async {
    setState(() => _isLoading = true);
    try {
      // Load all data
      await context.read<LeaseProvider>().loadAllLeases();
      await context.read<PaymentProvider>().loadAllPayments();
      await context.read<ExpenseProvider>().loadAllExpenses();
      await context.read<PropertyProvider>().loadProperties();
      await context.read<TenantProvider>().loadTenants();
      
      // Generate events
      _loadCalendarEvents();
      
      // Get device calendars
      await _getDeviceCalendars();
    } catch (e) {
      print('Error initializing calendar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getDeviceCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      setState(() {
        _availableCalendars = calendarsResult.data ?? [];
        if (_availableCalendars.isNotEmpty) {
          _selectedCalendar = _availableCalendars.first;
        }
      });
    } catch (e) {
      print('Error getting device calendars: $e');
    }
  }

  void _loadCalendarEvents() {
    // Clear existing events
    _events = {};
    
    // Load lease events
    _addLeaseEvents();
    
    // Load payment events
    _addPaymentEvents();
    
    // Load expense events
    _addExpenseEvents();
  }

  void _addLeaseEvents() {
    final leases = context.read<LeaseProvider>().leases;
    for (var lease in leases) {
      // Lease start events
      _addEvent(
        lease.startDate,
        CalendarEvent(
          title: 'Lease Start',
          description: 'Lease begins for property',
          type: EventType.leaseStart,
          lease: lease,
        ),
      );
      
      // Lease end events
      _addEvent(
        lease.endDate,
        CalendarEvent(
          title: 'Lease End',
          description: 'Lease expires for property',
          type: EventType.leaseEnd,
          lease: lease,
        ),
      );
      
      // Rent due events - create for the next 12 months
      DateTime rentDueDate = DateTime(lease.startDate.year, lease.startDate.month, 1);
      final now = DateTime.now();
      if (rentDueDate.isBefore(now)) {
        rentDueDate = DateTime(now.year, now.month, 1);
      }
      
      for (int i = 0; i < 12; i++) {
        final dueDate = DateTime(rentDueDate.year, rentDueDate.month + i, 1);
        if (dueDate.isBefore(lease.endDate)) {
          _addEvent(
            dueDate,
            CalendarEvent(
              title: 'Rent Due',
              description: 'Monthly rent payment due',
              type: EventType.rentDue,
              lease: lease,
              amount: lease.rentAmount,
            ),
          );
        }
      }
    }
  }

  void _addPaymentEvents() {
    final payments = context.read<PaymentProvider>().payments;
    final leaseProvider = context.read<LeaseProvider>();
    
    for (var payment in payments) {
      // Find the lease for this payment
      final leases = leaseProvider.leases.where((l) => l.id == payment.leaseId).toList();
      if (leases.isEmpty) continue;
      
      _addEvent(
        payment.paymentDate,
        CalendarEvent(
          title: 'Payment Received',
          description: 'Payment of \$${payment.amount.toStringAsFixed(2)} received',
          type: EventType.paymentReceived,
          amount: payment.amount,
          payment: payment,
          lease: leases.first,
        ),
      );
    }
  }

  void _addExpenseEvents() {
    final expenses = context.read<ExpenseProvider>().expenses;
    final properties = context.read<PropertyProvider>().properties;
    
    for (var expense in expenses) {
      // Find the property for this expense
      final matchingProperties = properties.where((p) => p.id == expense.propertyId).toList();
      if (matchingProperties.isEmpty) continue;
      
      final property = matchingProperties.first;
      
      _addEvent(
        expense.expenseDate,
        CalendarEvent(
          title: '${expense.expenseType} Expense',
          description: expense.description ?? 'Expense for ${property.address}',
          type: EventType.expense,
          amount: expense.amount,
          expense: expense,
          propertyId: property.id,
        ),
      );
    }
  }

  void _addEvent(DateTime date, CalendarEvent event) {
    final eventDate = DateTime(date.year, date.month, date.day);
    if (_events[eventDate] == null) {
      _events[eventDate] = [];
    }
    _events[eventDate]!.add(event);
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final eventDate = DateTime(day.year, day.month, day.day);
    return _events[eventDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeCalendar,
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _showSyncDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 3,
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: _selectedDay == null
                      ? Center(child: Text('Select a day to view events'))
                      : _buildEventList(),
                ),
              ],
            ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Center(child: Text('No events for this day'));
    }
    
    // Group events by type
    final Map<EventType, List<CalendarEvent>> groupedEvents = {};
    for (var event in events) {
      if (groupedEvents[event.type] == null) {
        groupedEvents[event.type] = [];
      }
      groupedEvents[event.type]!.add(event);
    }
    
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            DateFormat('MMMM d, yyyy').format(_selectedDay!),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(height: 8),
        ...groupedEvents.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  _getEventTypeTitle(entry.key),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _getEventTypeColor(entry.key),
                  ),
                ),
              ),
              ...entry.value.map((event) => _buildEventCard(event)),
            ],
          );
        }),
      ],
    );
  }

  String _getEventTypeTitle(EventType type) {
    switch (type) {
      case EventType.leaseStart:
        return 'Lease Start';
      case EventType.leaseEnd:
        return 'Lease End';
      case EventType.rentDue:
        return 'Rent Due';
      case EventType.paymentReceived:
        return 'Payments Received';
      case EventType.expense:
        return 'Expenses';
      default:
        return 'Events';
    }
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.leaseStart:
        return Colors.blue;
      case EventType.leaseEnd:
        return Colors.orange;
      case EventType.rentDue:
        return Colors.purple;
      case EventType.paymentReceived:
        return Colors.green;
      case EventType.expense:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEventCard(CalendarEvent event) {
    final propertyProvider = context.read<PropertyProvider>();
    final tenantProvider = context.read<TenantProvider>();
    
    String? propertyAddress;
    String? tenantName;
    
    if (event.lease != null) {
      // Get property info
      final matchingProperties = propertyProvider.properties
          .where((p) => p.id == event.lease!.propertyId)
          .toList();
      
      if (matchingProperties.isNotEmpty) {
        propertyAddress = matchingProperties.first.address;
      }
      
      // Get tenant info
      final matchingTenants = tenantProvider.tenants
          .where((t) => t.id == event.lease!.tenantId)
          .toList();
      
      if (matchingTenants.isNotEmpty) {
        final tenant = matchingTenants.first;
        tenantName = '${tenant.firstName} ${tenant.lastName}';
      }
    } else if (event.propertyId != null) {
      // Get property info for expense events
      final matchingProperties = propertyProvider.properties
          .where((p) => p.id == event.propertyId)
          .toList();
      
      if (matchingProperties.isNotEmpty) {
        propertyAddress = matchingProperties.first.address;
      }
    }
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEventTypeColor(event.type),
          child: Icon(
            _getEventTypeIcon(event.type),
            color: Colors.white,
          ),
        ),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (propertyAddress != null)
              Text('Property: $propertyAddress'),
            if (tenantName != null)
              Text('Tenant: $tenantName'),
            if (event.amount != null)
              Text('Amount: \$${event.amount!.toStringAsFixed(2)}'),
            if (event.description != null)
              Text(event.description!),
          ],
        ),
        isThreeLine: true,
        trailing: event.type == EventType.rentDue
            ? IconButton(
                icon: Icon(Icons.add_alert),
                onPressed: () => _addReminderToDeviceCalendar(event),
              )
            : null,
        onTap: () => _navigateToEventDetail(event),
      ),
    );
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.leaseStart:
        return Icons.home;
      case EventType.leaseEnd:
        return Icons.exit_to_app;
      case EventType.rentDue:
        return Icons.payment;
      case EventType.paymentReceived:
        return Icons.attach_money;
      case EventType.expense:
        return Icons.shopping_cart;
      default:
        return Icons.event;
    }
  }

  void _navigateToEventDetail(CalendarEvent event) {
    final propertyProvider = context.read<PropertyProvider>();
    final tenantProvider = context.read<TenantProvider>();
    
    switch (event.type) {
      case EventType.leaseStart:
      case EventType.leaseEnd:
      case EventType.rentDue:
        if (event.lease != null) {
          // Navigate to property detail
          final matchingProperties = propertyProvider.properties
              .where((p) => p.id == event.lease!.propertyId)
              .toList();
          
          if (matchingProperties.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(property: matchingProperties.first),
              ),
            );
          }
        }
        break;
      case EventType.paymentReceived:
        // Navigate to payment detail (assuming you have a PaymentDetailScreen)
        // For now, just navigate to the tenant
        if (event.lease != null) {
          final matchingTenants = tenantProvider.tenants
              .where((t) => t.id == event.lease!.tenantId)
              .toList();
          
          if (matchingTenants.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TenantDetailScreen(tenant: matchingTenants.first),
              ),
            );
          }
        }
        break;
      case EventType.expense:
        // Navigate to expense detail or property
        if (event.propertyId != null) {
          final matchingProperties = propertyProvider.properties
              .where((p) => p.id == event.propertyId)
              .toList();
          
          if (matchingProperties.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(property: matchingProperties.first),
              ),
            );
          }
        }
        break;
    }
  }

  Future<void> _showSyncDialog() async {
    if (_availableCalendars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No device calendars available')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sync with Device Calendar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a calendar to sync with:'),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCalendar?.id,
              decoration: InputDecoration(
                labelText: 'Calendar',
                border: OutlineInputBorder(),
              ),
              items: _availableCalendars.map((calendar) {
                return DropdownMenuItem(
                  value: calendar.id,
                  child: Text(calendar.name ?? 'Unknown Calendar'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCalendar = _availableCalendars.firstWhere(
                    (c) => c.id == value,
                  );
                });
              },
            ),
            SizedBox(height: 16),
            Text('What would you like to sync?'),
            CheckboxListTile(
              title: Text('Rent Due Dates'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: Text('Lease Start/End Dates'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: Text('Expenses'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _syncCalendar();
            },
            child: Text('Sync'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncCalendar() async {
    if (_selectedCalendar == null) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Syncing calendar...')),
      );
      
      // In a real app, you would iterate through events and add them to the device calendar
      // This is a simplified example that adds only rent due events
      
      final leases = context.read<LeaseProvider>().leases;
      int addedEvents = 0;
      
      for (var lease in leases) {
        // Only sync future events
        if (lease.endDate.isAfter(DateTime.now())) {
          final matchingProperties = context.read<PropertyProvider>().properties
              .where((p) => p.id == lease.propertyId)
              .toList();
          
          if (matchingProperties.isNotEmpty) {
            final property = matchingProperties.first;
            
            // Add rent due events
            DateTime rentDueDate = DateTime.now();
            final lastDayToAdd = lease.endDate;
            
            while (rentDueDate.isBefore(lastDayToAdd)) {
              // First day of next month
              rentDueDate = DateTime(rentDueDate.year, rentDueDate.month + 1, 1);
              
              await _addEventToDeviceCalendar(
                title: 'Rent Due: ${property.address}',
                description: 'Monthly rent payment of \$${lease.rentAmount} due',
                startDate: rentDueDate,
                allDay: true,
              );
              
              addedEvents++;
            }
            
            // Add lease end event
            await _addEventToDeviceCalendar(
              title: 'Lease Ends: ${property.address}',
              description: 'Lease contract expires',
              startDate: lease.endDate,
              allDay: true,
            );
            
            addedEvents++;
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $addedEvents events to your calendar')),
      );
    } catch (e) {
      print('Error syncing calendar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing calendar: $e')),
      );
    }
  }

  Future<void> _addReminderToDeviceCalendar(CalendarEvent event) async {
    if (_selectedCalendar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a calendar first')),
      );
      return;
    }
    
    if (event.lease == null) return;
    
    try {
      final matchingProperties = context.read<PropertyProvider>().properties
          .where((p) => p.id == event.lease!.propertyId)
          .toList();
      
      if (matchingProperties.isNotEmpty) {
        final property = matchingProperties.first;
        
        await _addEventToDeviceCalendar(
          title: 'Rent Due: ${property.address}',
          description: 'Monthly rent payment of \$${event.lease!.rentAmount} due',
          startDate: event.lease!.startDate,
          allDay: true,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder added to your calendar')),
        );
      }
    } catch (e) {
      print('Error adding reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding reminder: $e')),
      );
    }
  }

  Future<void> _addEventToDeviceCalendar({
    required String title,
    required String description,
    required DateTime startDate,
    bool allDay = false,
  }) async {
    if (_selectedCalendar == null) return;
    
    final event = Event(
      _selectedCalendar!.id,
      title: title,
      description: description,
      start: TZDateTime.from(startDate, local),
      end: TZDateTime.from(startDate.add(Duration(hours: allDay ? 24 : 1)), local),
      allDay: allDay,
    );
    
    await _deviceCalendarPlugin.createOrUpdateEvent(event);
  }
}

// Event Type Enum
enum EventType {
  leaseStart,
  leaseEnd,
  rentDue,
  paymentReceived,
  expense,
}

// Calendar Event Class
class CalendarEvent {
  final String title;
  final String? description;
  final EventType type;
  final Lease? lease;
  final Payment? payment;
  final Expense? expense;
  final String? propertyId;
  final double? amount;

  CalendarEvent({
    required this.title,
    this.description,
    required this.type,
    this.lease,
    this.payment,
    this.expense,
    this.propertyId,
    this.amount,
  });
}