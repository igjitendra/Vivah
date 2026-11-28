import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';

/// Filter scope for the Advanced Reports Hub.
enum ReportScopeFilter {
  all,
  milaOnly,
  diyaOnly,
  cashOnly,
  giftsOnly,
}

/// Time window used by the Overview Hero Ring card.
enum ReportHeroPeriod {
  thisMonth,
  quarter,
  selectedYear,
  allTime,
}

/// Aggregated stat row for a Person in Top Relatives rankings.
class RankedPersonStat {
  final String personId;
  final String name;
  final int totalPaise;
  final int count;

  const RankedPersonStat({
    required this.personId,
    required this.name,
    required this.totalPaise,
    required this.count,
  });
}

/// Aggregated stat row for an Event in Top Events breakdown.
class RankedEventStat {
  final String eventId;
  final String title;
  final EventType? eventType;
  final int receivedPaise;
  final int givenPaise;
  final int count;

  const RankedEventStat({
    required this.eventId,
    required this.title,
    this.eventType,
    required this.receivedPaise,
    required this.givenPaise,
    required this.count,
  });

  int get totalVolumePaise => receivedPaise + givenPaise;
}

/// Breakdown slice for the interactive Donut chart.
class CategorySliceStat {
  final String key;
  final EventType? eventType;
  final int count;
  final int volumePaise;

  const CategorySliceStat({
    required this.key,
    this.eventType,
    required this.count,
    required this.volumePaise,
  });
}

/// Hero Ring snapshot for the active [ReportHeroPeriod].
class HeroPeriodMetrics {
  final int receivedPaise;
  final int givenPaise;
  final int cashPaise;
  final int giftPaise;
  final int cashEntryCount;
  final int giftEntryCount;
  final int totalEntries;

  const HeroPeriodMetrics({
    required this.receivedPaise,
    required this.givenPaise,
    required this.cashPaise,
    required this.giftPaise,
    required this.cashEntryCount,
    required this.giftEntryCount,
    required this.totalEntries,
  });

  int get totalVolumePaise => receivedPaise + givenPaise;

  /// Percentage of Mila out of total recorded cash volume (0..100).
  int get milaSharePercent {
    final total = receivedPaise + givenPaise;
    if (total <= 0) {
      return 0;
    }
    return ((receivedPaise / total) * 100).round().clamp(0, 100);
  }

  /// Percentage of Cash out of Cash + Gift value (falls back to entry share if gift values are unpriced).
  int get cashSharePercent {
    final valueTotal = cashPaise + giftPaise;
    if (valueTotal > 0) {
      return ((cashPaise / valueTotal) * 100).round().clamp(0, 100);
    }
    final countTotal = cashEntryCount + giftEntryCount;
    if (countTotal <= 0) return 0;
    return ((cashEntryCount / countTotal) * 100).round().clamp(0, 100);
  }
}

/// Complete analytics computation engine for Vyavahaar Reports Hub.
/// Pure, single-pass aggregation preserving financial isolation (no Mila-Diya netting).
class VyavahaarStats {
  final List<TransactionEntry> filteredEntries;
  final int totalReceivedPaise;
  final int totalGivenPaise;
  final int receivedCount;
  final int givenCount;
  final int cashTotalPaise;
  final int estimatedGiftPaise;
  final int giftItemCount;
  final int pendingCount;
  final int pendingPaise;
  final int activeDays;
  final int avgEntryPaise;
  final int bestMonthIndex;
  final int bestMonthVolumePaise;
  final int heatmapYear;
  final List<int> availableYears;
  final List<int> monthlyReceivedPaise;
  final List<int> monthlyGivenPaise;
  final List<int> monthlyCounts;
  final List<int> weekdayCounts;
  final List<int> weekdayVolumePaise;
  final Map<String, int> dailyCounts;
  final Map<String, int> dailyVolumePaise;
  final List<RankedPersonStat> topPeopleReceived;
  final List<RankedPersonStat> topPeopleGiven;
  final List<RankedEventStat> topEvents;
  final List<CategorySliceStat> eventTypeSlices;
  final Map<TransactionType, int> modeCounts;
  final HeroPeriodMetrics heroMetrics;

  const VyavahaarStats({
    required this.filteredEntries,
    required this.totalReceivedPaise,
    required this.totalGivenPaise,
    required this.receivedCount,
    required this.givenCount,
    required this.cashTotalPaise,
    required this.estimatedGiftPaise,
    required this.giftItemCount,
    required this.pendingCount,
    required this.pendingPaise,
    required this.activeDays,
    required this.avgEntryPaise,
    required this.bestMonthIndex,
    required this.bestMonthVolumePaise,
    required this.heatmapYear,
    required this.availableYears,
    required this.monthlyReceivedPaise,
    required this.monthlyGivenPaise,
    required this.monthlyCounts,
    required this.weekdayCounts,
    required this.weekdayVolumePaise,
    required this.dailyCounts,
    required this.dailyVolumePaise,
    required this.topPeopleReceived,
    required this.topPeopleGiven,
    required this.topEvents,
    required this.eventTypeSlices,
    required this.modeCounts,
    required this.heroMetrics,
  });

  int get totalCount => filteredEntries.length;

  int get totalCombinedVolumePaise => totalReceivedPaise + totalGivenPaise;

  static bool isReceived(TransactionEntry entry) =>
      entry.direction == TransactionDirection.received ||
      entry.direction == TransactionDirection.mila;

  static DateTime _resolveDate(TransactionEntry entry) {
    return AppDateUtils.parseToLocalDate(entry.transactionDate) ?? entry.createdAt;
  }

  static String _toIsoKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static bool _matchesScope(TransactionEntry entry, ReportScopeFilter scope) {
    switch (scope) {
      case ReportScopeFilter.all:
        return true;
      case ReportScopeFilter.milaOnly:
        return isReceived(entry);
      case ReportScopeFilter.diyaOnly:
        return !isReceived(entry);
      case ReportScopeFilter.cashOnly:
        return entry.transactionType == TransactionType.cash ||
            entry.transactionType == TransactionType.cashAndItem;
      case ReportScopeFilter.giftsOnly:
        return entry.transactionType == TransactionType.item ||
            entry.transactionType == TransactionType.cashAndItem ||
            entry.items.isNotEmpty;
    }
  }

  /// Computes full analytics snapshot from [allEntries] and [events].
  static VyavahaarStats compute({
    required List<TransactionEntry> allEntries,
    required List<Event> events,
    ReportScopeFilter scope = ReportScopeFilter.all,
    int? selectedYear,
    String? selectedEventId,
    ReportHeroPeriod heroPeriod = ReportHeroPeriod.selectedYear,
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final eventLookup = {for (final ev in events) ev.id: ev};
    final yearsSet = <int>{now.year};

    // Pass 1: Collect available years + pending (planned) metrics matching event/scope/year.
    int pendingCount = 0;
    int pendingPaise = 0;
    final recordedBase = <TransactionEntry>[];

    for (final entry in allEntries) {
      if (entry.archivedAt != null) continue;
      final dt = _resolveDate(entry);
      yearsSet.add(dt.year);

      if (selectedEventId != null && entry.eventId != selectedEventId) continue;
      if (!_matchesScope(entry, scope)) continue;

      if (entry.status == TransactionStatus.planned) {
        if (selectedYear == null || dt.year == selectedYear) {
          pendingCount++;
          pendingPaise += entry.amountPaise ?? 0;
        }
        continue;
      }

      if (entry.status == TransactionStatus.recorded) {
        recordedBase.add(entry);
      }
    }

    // Hero period entries (scoped by Event + Direction/Mode, and either month/quarter/selectedYear/allTime).
    final heroEntries = recordedBase.where((entry) {
      final dt = _resolveDate(entry);
      switch (heroPeriod) {
        case ReportHeroPeriod.thisMonth:
          return dt.year == now.year && dt.month == now.month;
        case ReportHeroPeriod.quarter:
          final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
          return dt.year == now.year &&
              dt.month >= startMonth &&
              dt.month < startMonth + 3;
        case ReportHeroPeriod.selectedYear:
          return selectedYear == null || dt.year == selectedYear;
        case ReportHeroPeriod.allTime:
          return true;
      }
    }).toList();

    final filtered = selectedYear == null
        ? recordedBase
        : recordedBase.where((e) => _resolveDate(e).year == selectedYear).toList();

    int totalReceived = 0;
    int totalGiven = 0;
    int receivedCount = 0;
    int givenCount = 0;
    int cashTotal = 0;
    int giftValueTotal = 0;
    int giftItemCount = 0;

    final monthlyRec = List<int>.filled(12, 0);
    final monthlyGiv = List<int>.filled(12, 0);
    final monthlyCnt = List<int>.filled(12, 0);
    final weekdayCnt = List<int>.filled(7, 0);
    final weekdayVol = List<int>.filled(7, 0);
    final dailyCounts = <String, int>{};
    final dailyVol = <String, int>{};
    final activeDayKeys = <String>{};

    final peopleRecMap = <String, ({String name, int total, int count})>{};
    final peopleGivMap = <String, ({String name, int total, int count})>{};
    final eventsAgg = <String, ({String title, EventType? type, int rec, int giv, int count})>{};
    final typeAgg = <String, ({EventType? type, int count, int volume})>{};
    final modeCounts = <TransactionType, int>{
      TransactionType.cash: 0,
      TransactionType.item: 0,
      TransactionType.cashAndItem: 0,
    };

    final effectiveHeatmapYear = selectedYear ?? now.year;

    for (final e in filtered) {
      final dt = _resolveDate(e);
      final isoDay = _toIsoKey(dt);
      final amount = e.amountPaise ?? 0;
      final rec = isReceived(e);

      activeDayKeys.add(isoDay);
      cashTotal += amount;

      int itemValueSum = 0;
      for (final item in e.items) {
        giftItemCount++;
        itemValueSum += item.estimatedValuePaise ?? 0;
      }
      giftValueTotal += itemValueSum;

      if (rec) {
        totalReceived += amount;
        receivedCount++;
      } else {
        totalGiven += amount;
        givenCount++;
      }

      final mIdx = (dt.month - 1).clamp(0, 11);
      monthlyCnt[mIdx]++;
      if (rec) {
        monthlyRec[mIdx] += amount;
      } else {
        monthlyGiv[mIdx] += amount;
      }

      final wIdx = (dt.weekday - 1).clamp(0, 6);
      weekdayCnt[wIdx]++;
      weekdayVol[wIdx] += amount;

      if (dt.year == effectiveHeatmapYear) {
        dailyCounts[isoDay] = (dailyCounts[isoDay] ?? 0) + 1;
        dailyVol[isoDay] = (dailyVol[isoDay] ?? 0) + amount;
      }

      modeCounts[e.transactionType] = (modeCounts[e.transactionType] ?? 0) + 1;

      // Person breakdown
      final pName = (e.personName != null && e.personName!.trim().isNotEmpty)
          ? e.personName!.trim()
          : 'Unknown';
      final pMap = rec ? peopleRecMap : peopleGivMap;
      final prevP = pMap[e.personId];
      pMap[e.personId] = (
        name: prevP?.name ?? pName,
        total: (prevP?.total ?? 0) + amount,
        count: (prevP?.count ?? 0) + 1,
      );

      // Event breakdown
      final evId = (e.eventId != null && e.eventId!.isNotEmpty) ? e.eventId! : 'general';
      final linkedEvent = e.eventId != null ? eventLookup[e.eventId] : null;
      final evTitle = linkedEvent?.title ??
          ((e.eventTitle != null && e.eventTitle!.trim().isNotEmpty)
              ? e.eventTitle!.trim()
              : 'general');
      final prevE = eventsAgg[evId];
      eventsAgg[evId] = (
        title: prevE?.title ?? evTitle,
        type: prevE?.type ?? linkedEvent?.eventType,
        rec: (prevE?.rec ?? 0) + (rec ? amount : 0),
        giv: (prevE?.giv ?? 0) + (rec ? 0 : amount),
        count: (prevE?.count ?? 0) + 1,
      );

      // EventType slice breakdown
      final typeKey = linkedEvent != null ? linkedEvent.eventType.name : 'general';
      final prevT = typeAgg[typeKey];
      typeAgg[typeKey] = (
        type: linkedEvent?.eventType,
        count: (prevT?.count ?? 0) + 1,
        volume: (prevT?.volume ?? 0) + amount,
      );
    }

    int bestMonthIdx = 0;
    int bestMonthVol = 0;
    for (int i = 0; i < 12; i++) {
      final vol = monthlyRec[i] + monthlyGiv[i];
      if (vol > bestMonthVol || (vol == 0 && monthlyCnt[i] > monthlyCnt[bestMonthIdx])) {
        bestMonthVol = vol;
        bestMonthIdx = i;
      }
    }

    final topPeopleRec = peopleRecMap.entries
        .map((e) => RankedPersonStat(
              personId: e.key,
              name: e.value.name,
              totalPaise: e.value.total,
              count: e.value.count,
            ))
        .toList()
      ..sort((a, b) {
        final cmp = b.totalPaise.compareTo(a.totalPaise);
        return cmp != 0 ? cmp : b.count.compareTo(a.count);
      });

    final topPeopleGiv = peopleGivMap.entries
        .map((e) => RankedPersonStat(
              personId: e.key,
              name: e.value.name,
              totalPaise: e.value.total,
              count: e.value.count,
            ))
        .toList()
      ..sort((a, b) {
        final cmp = b.totalPaise.compareTo(a.totalPaise);
        return cmp != 0 ? cmp : b.count.compareTo(a.count);
      });

    final topEvents = eventsAgg.entries
        .where((e) => e.key != 'general' || eventsAgg.length == 1)
        .map((e) => RankedEventStat(
              eventId: e.key,
              title: e.value.title,
              eventType: e.value.type,
              receivedPaise: e.value.rec,
              givenPaise: e.value.giv,
              count: e.value.count,
            ))
        .toList()
      ..sort((a, b) {
        final cmp = b.totalVolumePaise.compareTo(a.totalVolumePaise);
        return cmp != 0 ? cmp : b.count.compareTo(a.count);
      });

    final eventTypeSlices = typeAgg.entries
        .map((e) => CategorySliceStat(
              key: e.key,
              eventType: e.value.type,
              count: e.value.count,
              volumePaise: e.value.volume,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Hero Period metrics
    int heroRec = 0;
    int heroGiv = 0;
    int heroCash = 0;
    int heroGift = 0;
    int heroCashCount = 0;
    int heroGiftCount = 0;

    for (final e in heroEntries) {
      final amt = e.amountPaise ?? 0;
      if (isReceived(e)) {
        heroRec += amt;
      } else {
        heroGiv += amt;
      }
      heroCash += amt;
      if (e.transactionType == TransactionType.cash ||
          e.transactionType == TransactionType.cashAndItem) {
        heroCashCount++;
      }
      if (e.transactionType == TransactionType.item ||
          e.transactionType == TransactionType.cashAndItem ||
          e.items.isNotEmpty) {
        heroGiftCount++;
      }
      for (final item in e.items) {
        heroGift += item.estimatedValuePaise ?? 0;
      }
    }

    final sortedYears = yearsSet.toList()..sort((a, b) => b.compareTo(a));
    final avgPaise = filtered.isEmpty ? 0 : (cashTotal / filtered.length).round();

    return VyavahaarStats(
      filteredEntries: filtered,
      totalReceivedPaise: totalReceived,
      totalGivenPaise: totalGiven,
      receivedCount: receivedCount,
      givenCount: givenCount,
      cashTotalPaise: cashTotal,
      estimatedGiftPaise: giftValueTotal,
      giftItemCount: giftItemCount,
      pendingCount: pendingCount,
      pendingPaise: pendingPaise,
      activeDays: activeDayKeys.length,
      avgEntryPaise: avgPaise,
      bestMonthIndex: bestMonthIdx,
      bestMonthVolumePaise: bestMonthVol,
      heatmapYear: effectiveHeatmapYear,
      availableYears: sortedYears,
      monthlyReceivedPaise: monthlyRec,
      monthlyGivenPaise: monthlyGiv,
      monthlyCounts: monthlyCnt,
      weekdayCounts: weekdayCnt,
      weekdayVolumePaise: weekdayVol,
      dailyCounts: dailyCounts,
      dailyVolumePaise: dailyVol,
      topPeopleReceived: topPeopleRec.take(8).toList(),
      topPeopleGiven: topPeopleGiv.take(8).toList(),
      topEvents: topEvents.take(8).toList(),
      eventTypeSlices: eventTypeSlices,
      modeCounts: modeCounts,
      heroMetrics: HeroPeriodMetrics(
        receivedPaise: heroRec,
        givenPaise: heroGiv,
        cashPaise: heroCash,
        giftPaise: heroGift,
        cashEntryCount: heroCashCount,
        giftEntryCount: heroGiftCount,
        totalEntries: heroEntries.length,
      ),
    );
  }
}
