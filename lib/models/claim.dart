class Claim {
  final int? id;
  final String homeownerName;
  final String address;
  final String phoneNumber;
  final String insuranceCompany;
  final String claimNumber;
  final String status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Claim({
    this.id,
    required this.homeownerName,
    required this.address,
    required this.phoneNumber,
    required this.insuranceCompany,
    required this.claimNumber,
    required this.status,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'homeownerName': homeownerName,
      'address': address,
      'phoneNumber': phoneNumber,
      'insuranceCompany': insuranceCompany,
      'claimNumber': claimNumber,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Claim.fromMap(Map<String, dynamic> map) {
    return Claim(
      id: map['id'] as int?,
      homeownerName: map['homeownerName'] as String,
      address: map['address'] as String,
      phoneNumber: map['phoneNumber'] as String,
      insuranceCompany: map['insuranceCompany'] as String,
      claimNumber: map['claimNumber'] as String,
      status: map['status'] as String,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Claim copyWith({
    int? id,
    String? homeownerName,
    String? address,
    String? phoneNumber,
    String? insuranceCompany,
    String? claimNumber,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Claim(
      id: id ?? this.id,
      homeownerName: homeownerName ?? this.homeownerName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      claimNumber: claimNumber ?? this.claimNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Claim status stages based on business flow
class ClaimStatus {
  static const String hailEvent = 'Hail Event';
  static const String customerOutreach = 'Customer Outreach';
  static const String inspection = 'Inspection & Evidence';
  static const String claimEnablement = 'Claim Enablement';
  static const String claimManagement = 'Claim Management';
  static const String claimApproval = 'Claim Approval';
  static const String roofConstruction = 'Roof Construction';
  static const String progressValidation = 'Progress Validation';
  static const String paymentFlow = 'Payment Flow';
  static const String projectClosure = 'Project Closure';

  static List<String> getAllStatuses() {
    return [
      hailEvent,
      customerOutreach,
      inspection,
      claimEnablement,
      claimManagement,
      claimApproval,
      roofConstruction,
      progressValidation,
      paymentFlow,
      projectClosure,
    ];
  }

  static int getStatusIndex(String status) {
    return getAllStatuses().indexOf(status);
  }

  static String? getNextStatus(String currentStatus) {
    final statuses = getAllStatuses();
    final currentIndex = statuses.indexOf(currentStatus);
    if (currentIndex >= 0 && currentIndex < statuses.length - 1) {
      return statuses[currentIndex + 1];
    }
    return null;
  }
}
