import 'package:flutter_test/flutter_test.dart';
import 'package:g_shipping/features/shifts/models/shift_model.dart';

void main() {
  Shift shift({
    required DateTime start,
    required DateTime end,
    String status = 'pending',
  }) => Shift(
    id: 'shift-1',
    startTime: start,
    endTime: end,
    location: 'Kho',
    status: status,
  );

  test('ca chỉ hoàn thành khi trạng thái đã được xác nhận', () {
    final now = DateTime.now();
    final overdue = shift(
      start: now.subtract(const Duration(hours: 3)),
      end: now.subtract(const Duration(hours: 1)),
    );
    expect(overdue.isCompleted, isFalse);
    expect(overdue.statusLabel, 'Quá hạn');

    final completed = shift(
      start: now.subtract(const Duration(hours: 3)),
      end: now.subtract(const Duration(hours: 1)),
      status: 'completed',
    );
    expect(completed.isCompleted, isTrue);
    expect(completed.statusLabel, 'Đã hoàn thành');
  });

  test('ca đang diễn ra không nằm trong lịch sử', () {
    final now = DateTime.now();
    final active = shift(
      start: now.subtract(const Duration(minutes: 30)),
      end: now.add(const Duration(minutes: 30)),
    );
    expect(active.statusLabel, 'Đang thực hiện');
  });
}
