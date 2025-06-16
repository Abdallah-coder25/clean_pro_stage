import '../../core/models/booking.dart';
import '../../core/models/user.dart';

class CleanerScore {
  final String cleanerId;
  final double completionRate;
  final double serviceExperience;
  final int todayWorkload;
  final double rating;
  final int totalTasks;
  final int completedTasks;

  const CleanerScore({
    required this.cleanerId,
    required this.completionRate,
    required this.serviceExperience,
    required this.todayWorkload,
    required this.rating,
    required this.totalTasks,
    required this.completedTasks,
  });
}

class ScoredCleaner {
  final User cleaner;
  final CleanerScore score;
  final double combinedScore;

  const ScoredCleaner({
    required this.cleaner,
    required this.score,
    required this.combinedScore,
  });
}

class BookingOptimizer {
  /// Recommends cleaners for a specific service based on performance metrics
  static List<ScoredCleaner> recommendCleanersForBooking({
    required List<Booking> bookings,
    required List<User> cleaners,
    required String serviceId,
  }) {
    if (cleaners.isEmpty) return [];

    final now = DateTime.now();
    final recommendations = <ScoredCleaner>[];

    for (final cleaner in cleaners) {
      // Get all bookings for this cleaner
      final cleanerBookings = bookings
          .where((b) => b.cleanerId == cleaner.id)
          .toList();

      // Calculate completion rate
      final completedBookings = cleanerBookings
          .where((b) => b.status == BookingStatus.completed)
          .length;
      final completionRate = cleanerBookings.isNotEmpty
          ? completedBookings / cleanerBookings.length
          : 0.5; // Default score for new cleaners

      // Calculate service experience
      final serviceBookings = cleanerBookings
          .where(
            (b) =>
                b.serviceId == serviceId && b.status == BookingStatus.completed,
          )
          .length;
      final serviceExperience = serviceBookings / (cleanerBookings.length + 1);

      // Calculate today's workload
      final todayBookings = cleanerBookings
          .where(
            (b) =>
                b.dateTime.year == now.year &&
                b.dateTime.month == now.month &&
                b.dateTime.day == now.day,
          )
          .length;

      // Calculate average rating (mock data - could be replaced with real ratings)
      final rating = (completionRate * 5).clamp(3.0, 5.0);

      final score = CleanerScore(
        cleanerId: cleaner.id,
        completionRate: completionRate,
        serviceExperience: serviceExperience,
        todayWorkload: todayBookings,
        rating: rating,
        totalTasks: cleanerBookings.length,
        completedTasks: completedBookings,
      );

      // Calculate combined score - higher is better
      final combinedScore =
          (score.completionRate * 0.3) + // 30% weight on completion rate
          (score.serviceExperience *
              0.3) + // 30% weight on service-specific experience
          ((5 - score.todayWorkload) /
              5 *
              0.2) + // 20% weight on available capacity
          (score.rating / 5 * 0.2); // 20% weight on rating

      recommendations.add(
        ScoredCleaner(
          cleaner: cleaner,
          score: score,
          combinedScore: combinedScore,
        ),
      );
    }

    // Sort by combined score (highest first)
    recommendations.sort((a, b) => b.combinedScore.compareTo(a.combinedScore));
    return recommendations;
  }

  /// Suggests optimal assignments for a list of unassigned bookings
  static Map<String, List<Booking>> suggestAssignments({
    required List<Booking> bookings,
    required List<User> cleaners,
  }) {
    if (cleaners.isEmpty) return {}; // Get unassigned bookings
    final unassignedBookings = bookings
        .where((b) => b.cleanerId == null || b.cleanerId?.isEmpty == true)
        .toList();

    if (unassignedBookings.isEmpty) return {};

    // Calculate current workload
    final cleanerWorkload = <String, int>{};
    for (final cleaner in cleaners) {
      cleanerWorkload[cleaner.id] = bookings
          .where(
            (b) =>
                b.cleanerId == cleaner.id &&
                b.status != BookingStatus.completed,
          )
          .length;
    }

    // Calculate cleaner performance score
    final cleanerPerformance = <String, double>{};
    for (final cleaner in cleaners) {
      final completedBookings = bookings
          .where(
            (b) =>
                b.cleanerId == cleaner.id &&
                b.status == BookingStatus.completed,
          )
          .length;
      final totalAssigned = bookings
          .where((b) => b.cleanerId == cleaner.id)
          .length;
      cleanerPerformance[cleaner.id] = totalAssigned > 0
          ? completedBookings / totalAssigned
          : 0.5; // Default score for new cleaners
    }

    // Suggest assignments
    final suggestions = <String, List<Booking>>{};

    // Sort unassigned bookings by date (earlier first)
    unassignedBookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    for (final booking in unassignedBookings) {
      String? bestCleaner;
      var bestScore = double.negativeInfinity;

      for (final cleaner in cleaners) {
        // Get recommended cleaners for this specific service
        final recommendation = recommendCleanersForBooking(
          bookings: bookings,
          cleaners: [cleaner],
          serviceId: booking.serviceId,
        );

        if (recommendation.isEmpty) continue;

        // Higher score is better - combines service-specific score with workload
        final score =
            recommendation.first.combinedScore -
            (cleanerWorkload[cleaner.id] ?? 0) *
                0.1; // Penalty for high workload

        if (score > bestScore) {
          bestScore = score;
          bestCleaner = cleaner.id;
        }
      }

      if (bestCleaner != null) {
        suggestions[bestCleaner] = [
          ...(suggestions[bestCleaner] ?? []),
          booking,
        ];
        // Update workload for next iteration
        cleanerWorkload[bestCleaner] = (cleanerWorkload[bestCleaner] ?? 0) + 1;
      }
    }

    return suggestions;
  }
}
