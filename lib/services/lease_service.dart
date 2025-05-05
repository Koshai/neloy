import '../models/lease.dart';
import 'database_service.dart';

class LeaseService {
  final _databaseService = DatabaseService();

  Future<void> archiveExpiredLeases() async {
    final now = DateTime.now();
    
    // Find all expired leases
    final expiredLeases = await _databaseService.getExpiredLeases(now);
    
    // Update lease status to expired
    for (var lease in expiredLeases) {
      await _databaseService.updateLeaseStatus(lease.id, 'expired');
      
      // Mark property as available
      await _databaseService.updatePropertyAvailability(lease.propertyId, true);
    }
  }

  Future<void> archiveTenant(String tenantId) async {
    // You might want to add a status field to tenant model
    // or move tenant to an archive table
    await _databaseService.updateTenantStatus(tenantId, 'archived');
  }
}