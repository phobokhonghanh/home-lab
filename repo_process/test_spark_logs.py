from pyspark.sql import SparkSession
import time
import os

log_dir = "/opt/bitnami/spark/logs"
if not os.path.exists(log_dir):
    os.makedirs(log_dir, exist_ok=True)

# 1. Khởi tạo Spark Session với các cấu hình log đã thiết lập
spark = (
    SparkSession.builder
    .appName("Log Testing App")
    .master("spark://spark-master:7077")

    # Khai báo Driver ID để Worker có thể liên lạc ngược lại (Quan trọng trong Docker)
    .config("spark.driver.host", "notebook_jupyter-lab")
    .config("spark.driver.bindAddress", "0.0.0.0")

    # Cấu hình đường dẫn Log theo chuẩn mới chúng ta vừa sửa
    .config("spark.eventLog.enabled", "true")
    .config("spark.eventLog.dir", "/opt/bitnami/spark/logs")
    .config("spark.history.fs.logDirectory", "/opt/bitnami/spark/logs")

    .getOrCreate()
)

sc = spark.sparkContext
print(">>> Spark Session đã khởi tạo. Driver đang ghi log vào /opt/bitnami/spark/logs")

try:
    # 2. Thực hiện một tác vụ tính toán đơn giản để sinh ra sự kiện (Events)
    print(">>> Đang chạy tác vụ tính toán...")
    rdd = sc.parallelize(range(1000), 10)
    result = rdd.map(lambda x: x * x).reduce(lambda x, y: x + y)

    print(f">>> Kết quả tính toán: {result}")
    print(">>> Đang giữ session trong 30 giây để bạn kiểm tra mục 'Incomplete Applications' trên History Server...")

    # Nghỉ một chút để bạn kịp vào Web UI (cổng 18080) xem trạng thái đang chạy
    time.sleep(30)

finally:
    # 3. Đóng Session (Rất quan trọng)
    # Lệnh này sẽ giúp Spark đổi tên file từ '.inprogress' thành file hoàn chỉnh
    print(">>> Đang đóng Spark Session để hoàn tất ghi log.")
    spark.stop()
    print(">>> Đã xong. Hãy kiểm tra mục 'Completed Applications' trên History Server.")
