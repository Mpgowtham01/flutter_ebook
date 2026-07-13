class SubscriptionModel {
  final String id;
  final String plan;
  final String status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;

  const SubscriptionModel({
    required this.id,
    required this.plan,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
  });

  bool get isActive => status == 'active';

  bool get isExpired {
    return currentPeriodEnd.isBefore(DateTime.now());
  }

  String get planDisplayName {
    switch (plan) {
      case 'monthly':
        return 'Monthly Plan';
      case 'yearly':
        return 'Yearly Plan';
      default:
        return 'Free';
    }
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['_id'] as String,
      plan: json['plan'] as String,
      status: json['status'] as String,
      currentPeriodStart: DateTime.parse(json['currentPeriodStart'] as String),
      currentPeriodEnd: DateTime.parse(json['currentPeriodEnd'] as String),
    );
  }
}
