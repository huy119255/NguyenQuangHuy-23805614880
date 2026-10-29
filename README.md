# Ứng dụng chấm công Nhóm 6

Ứng dụng Flutter hỗ trợ phân quyền Admin, Nhân viên và Khách hàng. Admin quản lý nhân viên bằng CRUD; nhân viên check-in/check-out bằng phương thức GPS và hệ thống lưu lại ca làm việc.

## Chạy Flutter trên Android Emulator

Backend local dùng cổng HTTP `5293` theo `launchSettings.json`. Android Emulator truy cập máy host bằng `10.0.2.2`:

```powershell
dotnet run --launch-profile http --project .\NguyenQuangHuy_23805614880_API
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5293
```

Nếu API đã deploy, truyền URL HTTPS thật bằng `--dart-define=API_BASE_URL=...`.

## Cấu hình API production

Đặt `ConnectionStrings__DefaultConnection` và `Jwt__Key` trong môi trường deploy. `Jwt__Key` phải là chuỗi Base64 đủ dài; không commit secret production vào source code. API dùng OpenAPI ở `/openapi/v1.json` khi chạy Development.