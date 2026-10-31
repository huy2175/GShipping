# GShipping

Ứng dụng Flutter quản lý địa điểm khách hàng và ca làm việc. Bản đồ trong ứng dụng dùng OpenStreetMap; nút **Xem trên Google Maps** và **Chỉ đường** mở Google Maps từ tọa độ đã chọn.

## Chức năng hiện có

- Đăng ký, đăng nhập bằng Firebase Authentication.
- Chạm hoặc ghim điểm trên bản đồ để xem tọa độ, địa chỉ gần đúng và lưu khách hàng.
- Xem lại khách hàng đã lưu trên bản đồ, tìm kiếm, sửa thông tin và chọn lại tọa độ khi đổi địa chỉ.
- Tạo ca với địa điểm, tọa độ thực, giờ bắt đầu/kết thúc và danh sách khách hàng; xem khách hàng của ca trên bản đồ.
- Chụp ảnh đơn hàng hoặc biên nhận bằng camera để xác nhận hoàn thành ca. Ảnh được tải lên Cloudinary, URL và thời điểm hoàn thành lưu trong Firestore.
- Chỉnh sửa hồ sơ và đăng xuất.

Ứng dụng hiện **chưa có mô hình đơn hàng, mã vận đơn hoặc theo dõi giao hàng**. Ảnh hoàn thành được gắn với **ca**, không phải từng đơn hàng. Tên quán hoặc tòa nhà tại một điểm phụ thuộc dữ liệu bản đồ; dùng nút Google Maps để xem thông tin địa điểm đầy đủ hơn. Tìm địa chỉ dùng geocoding trên Android/iOS và Photon trên Web/desktop; public Photon demo phù hợp lưu lượng vừa phải, không cam kết uptime và có thể giới hạn truy vấn nhiều.

## Chạy project

1. Cài Flutter SDK và cấu hình Firebase cho nền tảng cần chạy.
2. Chạy `flutter pub get`.
3. Chạy `flutter run` hoặc `flutter run -d chrome`.

Để tải ảnh, preset Cloudinary `gshipping_preset` phải hoạt động. Kiểm tra quyền camera, vị trí và mạng trên thiết bị. Chạy `flutter test` để kiểm tra trạng thái ca.

## Dữ liệu và triển khai

Firestore dùng các collection `customers`, `shifts` và `users`. Trước khi triển khai cho nhiều tài khoản, cần thiết kế phân quyền Firestore Security Rules và phương án chuyển dữ liệu cũ. Hiện mã ứng dụng chưa tách khách hàng/ca theo chủ sở hữu; không dùng cấu hình Firestore cho phép mọi người đọc và ghi dữ liệu trong môi trường thật.

Các đề xuất về giao diện tương lai ở [design.md](design.md) chưa phải chức năng đã triển khai.
