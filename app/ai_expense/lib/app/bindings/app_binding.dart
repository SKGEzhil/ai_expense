import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/analytics_controller.dart';
import '../controllers/event_controller.dart';
import '../services/api_service.dart';

/// App-wide dependency injection binding
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Register API service
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
    
    // Register controllers
    Get.lazyPut<TransactionController>(() => TransactionController(), fenix: true);
    Get.lazyPut<AnalyticsController>(() => AnalyticsController(), fenix: true);
    Get.lazyPut<EventController>(() => EventController(), fenix: true);
  }
}
