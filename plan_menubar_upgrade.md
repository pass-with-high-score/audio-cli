# Kế Hoạch Nâng Cấp "Vũ Trụ" Cho Mac Menu Bar (Mini-Player)

Hiện tại Menu Bar của chúng ta mới ở mức "đẹp và xài được". Để biến nó thành một ứng dụng chuẩn Apple "xịn xò" (Premium) khiến ai nhìn cũng phải trầm trồ, chúng ta sẽ đắp thêm các "vũ khí hạng nặng" sau đây bằng SwiftUI:

---

## 🌟 1. Tích Hợp Sâu Vào Lõi macOS (System Native)
- **Now Playing Info Center:** Đồng bộ hóa bài hát đang phát với **Control Center** của Mac và **Màn hình khóa (Lock Screen)**. Bạn có thể bấm phím Play/Pause cứng trên bàn phím MacBook và nhạc vẫn tự dừng/phát.
- **Dynamic Status Icon:** Biểu tượng nốt nhạc trên thanh Menu sẽ không đứng yên nữa. Ta sẽ làm nó chuyển động (nhấp nháy hoặc biến thành cột sóng audio mini) khi nhạc đang phát, và đổi thành nút Pause khi dừng.

## 🎛 2. Giao Diện Tương Tác Kéo Thả (Interactive Controls)
- **Thanh Tiến Độ (Scrubber/Timeline):** Thêm một thanh Progress Bar ở dưới ảnh bìa. Không chỉ để nhìn, mà bạn có thể **kéo thả chuột (scrub)** để tua nhanh đoạn điệp khúc. Giao diện Swift sẽ gọi API `POST /seek` xuống Go.
- **Thanh Âm Lượng (Volume Slider):** Thêm thanh gạt Volume cong cong mờ ảo đặc trưng của Apple. Vuốt nhẹ là thay đổi âm lượng mượt mà.

## 🎨 3. Hiệu Ứng Bắt Mắt (Micro-Animations & UI)
- **Chữ Chạy (Marquee Text):** Nếu tên bài hát quá dài, thay vì bị cắt cụt (dấu 3 chấm), dòng chữ sẽ từ từ trượt ngang qua lại (giống hệt màn hình LED trên xe bus hoặc Spotify).
- **Haptic Feedback & Scale:** Nút Play/Pause khi bấm vào sẽ có hiệu ứng lõm xuống nhẹ (Scale Effect) và đổi màu gradient bắt mắt thay vì chỉ hiện màu đen trắng.

## 🔍 4. Mở Rộng Tính Năng Trực Tiếp Từ Popover
- **Xem Danh Sách Chờ (Playlist Queue):** Bấm một nút nhỏ để bảng Popover lật sang mặt sau (3D Flip) hiển thị danh sách các bài hát tiếp theo.
- **Search Nhanh (Quick Search):** Một ô gõ tìm kiếm cực nhỏ giấu trên đỉnh, gõ tên bài và nhấn Enter là nhạc tự đổi, khỏi cần mở lại cửa sổ Terminal đen ngòm kia nữa!

---

### Lộ Trình Triển Khai
Bạn chọn món nào để tôi nấu trước? 
👉 **Gói 1 (Dễ, sướng ngay):** Thanh tua nhạc, Thanh Volume và Chữ chạy.
👉 **Gói 2 (Pro, chuẩn Mac):** Đồng bộ Control Center, phím cứng bàn phím và Icon động trên Menu Bar.
