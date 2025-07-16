=== Class
class FinanceRecord:
   def __init__(self, id, doanh_thu, chi_phi, ghi_chu, ngay_tao):
        self.id = id
        self.doanh_thu = doanh_thu
        self.chi_phi = chi_phi
        self.ghi_chu = ghi_chu
        self.ngay_tao = ngay_tao
class Report:
  def __init__(self,total_revenue,total_cost,total_profit,type_report):
    self.total_revenue = total_revenue
    self.total_cost = total_cost
    self.total_profit = total_profit - total_cost

API Key Gemini
api_keys = ["AIzaSyBEfaLoEVOYc2Tft0m63Ae8HuxwaF8pCdA","AIzaSyDmoMtVlGQqKQ8D1fHOxuP5ZBdEQvAgyO4","AIzaSyBCSfatIlev3xZN9MrQlIhSu_dYrxoaExY"]

def prompt_type_input(user_input):
  """Phân tích input của user để xác định loại yêu cầu: entry hoặc report"""
  prompt_text = f"""Bạn là AI chuyên xử lý dữ liệu tài chính Việt Nam.
  DateTime: {datetime.now()}
  Context: Người dùng yêu cầu nhập hoặc báo cáo
  Task: Hãy xác định chính xác yêu cầu của người dùng và chuyển đổi thành JSON

  Examples:
  Input: 'Hôm nay bán được 500k, mua hàng hết 300k'
  Output: {{"type_input": "entry"}}

  Input: 'Báo cáo doanh thu quý 3'
  Output: {{"type_input": "report", "report_type": "quy", "period": 3, "year": 2025}}

  Input: 'Báo cáo tháng 7'
  Output: {{"type_input": "report", "report_type": "thang", "period": 7, "year": 2025}}

  Input: 'Báo cáo năm 2024'
  Output: {{\"type_input\": "report", "report_type": "nam", "year": 2024}}

  Input: 'Xem báo cáo hôm nay'
  Output: {{"type_input": "report", "report_type": "ngay", "date": "{datetime.now().strftime('%Y-%m-%d')}"}}

  Input: 'Kế toán là gì'
  Output: {{"type_input": "Search"}}


  Hãy phân tích dữ liệu sau: {user_input}"""
  return prompt_text

  def write_prompt_text(user_input):
    prompt_text = "Bạn là AI chuyên xử lý dữ liệu tài chính Việt Nam."\
    f"Thời gian hiện tại: {datetime.now().strftime('%Y-%m-%d')}"\
    "Context: Người dùng sẽ nói về doanh thu và chi phí trong ngày. Nếu tiền nợ sẽ tính vào tiền chi phí"\
    "Task: Trích xuất chính xác số tiền và chuyển đổi thành JSON."\
    "Examples: Input: 'Hôm nay bán được 500k, mua hàng hết 300k' "\
    "Output: {\"doanh_thu\": 500000, \"chi_phi\": 300000,\"ghi_chu\": Lấy thông tin từ input có thể để trống, \"ngay_tao\": \"2024-01-15\"} "\
    "Input: \"Thu về 2 triệu 5, chi tiêu 1 triệu 2\""\
    "Output: {\"doanh_thu\": 2500000, \"chi_phi\": 1200000,\"ghi_chu\": Lấy thông tin từ input có thể để trống, \"ngay_tao\": \"2024-01-15\"} Response (JSON only) không có Json''' data ''':"\
    "Nếu dữ liệu không liên quan thì trả về 'Error'"\
    f"Hãy phân tích dữ liệu sau:{user_input}"
    return prompt_text

def clean_text_json(text):
  clean_json = text.strip("` \n")
  if clean_json.startswith("json"):
    clean_json = clean_json[4:]
  return clean_json

def format_strin_to_datetime(ngay_tao_input):
  """Hàm duy nhất để chuyển đổi ngay_tao từ bất kỳ định dạng nào thành datetime"""
  if isinstance(ngay_tao_input, str):
    if ngay_tao_input == "ngay_tao":
      return datetime.now()

    # Thử parse các format datetime phổ biến
    formats_to_try = [
      '%Y-%m-%d %H:%M:%S.%f',  # 2025-01-15 10:30:45.123456
      '%Y-%m-%d %H:%M:%S',     # 2025-01-15 10:30:45
      '%Y-%m-%d',              # 2025-01-15
      '%d/%m/%Y %H:%M:%S',     # 15/01/2025 10:30:45
      '%d/%m/%Y',              # 15/01/2025
      '%d-%m-%Y %H:%M:%S',     # 15-01-2025 10:30:45
      '%d-%m-%Y'               # 15-01-2025
    ]

    for fmt in formats_to_try:
      try:
        return datetime.strptime(ngay_tao_input, fmt)
      except ValueError:
        continue

    try:
      # Thử ISO format cuối cùng
      return datetime.fromisoformat(ngay_tao_input.replace('Z', '+00:00'))
    except (ValueError, AttributeError):
      return datetime.now()

  elif hasattr(ngay_tao_input, 'month') and hasattr(ngay_tao_input, 'year'):
    # Đã là datetime object
    return ngay_tao_input
  else:
    return datetime.now()


# Gemini
def call_api(model_ai, user_input, max_retries=None):
    global error_key, client

    if max_retries is None:
        max_retries = len(api_keys)

    attempts = 0

    while attempts < max_retries:
        try:
            response = client.models.generate_content(
                model=model_ai,
                contents=user_input,
            )
            # Kiểm tra nếu response trả về "Error"
            if hasattr(response, 'text') and response.text == "Error":
                raise Exception("API returned Error")
            return response

        except Exception as e:
            attempts += 1
            if attempts < max_retries:
                # Chuyển sang API key tiếp theo
                if error_key == len(api_keys) - 1:
                    error_key = 0
                else:
                    error_key += 1
                print(f"Lỗi xảy ra: {e}")
                print(f"Đổi api_key thứ {error_key + 1}: {api_keys[error_key]}")
                client = genai.Client(api_key=api_keys[error_key])
            else:
                print(f"Đã thử hết {max_retries} API keys nhưng vẫn lỗi: {e}")
                raise Exception(f"API call failed after {max_retries} attempts")

def total_revenue(input_data):
  try:
    total = 0
    for item in input_data:
      total += item.doanh_thu
    return total
  except Exception as e:
    return 0

def total_cost(input_data):
  try:
    total = 0
    for item in input_data:
      total += item.chi_phi
    return total
  except Exception as e:
    return 0

def bao_cao_thang(lst_data, thang, nam):
  """Báo cáo doanh thu và chi phí theo tháng"""
  tong_doanh_thu = 0
  tong_chi_phi = 0
  so_giao_dich = 0

  print(f"\n=== BÁO CÁO THÁNG {thang}/{nam} ===")

  for item in lst_data:
    ngay_tao = item.ngay_tao if hasattr(item, 'ngay_tao') else item.__dict__.get('ngay_tao')
    if ngay_tao and ngay_tao.month == thang and ngay_tao.year == nam:
      tong_doanh_thu += item.doanh_thu if hasattr(item, 'doanh_thu') else item.__dict__.get('doanh_thu', 0)
      tong_chi_phi += item.chi_phi if hasattr(item, 'chi_phi') else item.__dict__.get('chi_phi', 0)
      so_giao_dich += 1

  loi_nhuan = tong_doanh_thu - tong_chi_phi

  print(f"Tổng doanh thu: {tong_doanh_thu:,} VNĐ")
  print(f"Tổng chi phí: {tong_chi_phi:,} VNĐ")
  print(f"Lợi nhuận: {loi_nhuan:,} VNĐ")
  print(f"Số giao dịch: {so_giao_dich}")
  if tong_doanh_thu > 0:
    print(f"Tỷ lệ lợi nhuận: {(loi_nhuan/tong_doanh_thu)*100:.2f}%")
  print("="*40)

def bao_cao_quy(lst_data, quy, nam):
  """Báo cáo doanh thu và chi phí theo quý"""
  thang_dau = (quy - 1) * 3 + 1
  thang_cuoi = quy * 3

  tong_doanh_thu = 0
  tong_chi_phi = 0
  so_giao_dich = 0

  print(f"\n=== BÁO CÁO QUÝ {quy}/{nam} (Tháng {thang_dau}-{thang_cuoi}) ===")

  for item in lst_data:
    ngay_tao = item.ngay_tao if hasattr(item, 'ngay_tao') else item.__dict__.get('ngay_tao')
    if ngay_tao and thang_dau <= ngay_tao.month <= thang_cuoi and ngay_tao.year == nam:
      tong_doanh_thu += item.doanh_thu if hasattr(item, 'doanh_thu') else item.__dict__.get('doanh_thu', 0)
      tong_chi_phi += item.chi_phi if hasattr(item, 'chi_phi') else item.__dict__.get('chi_phi', 0)
      so_giao_dich += 1

  loi_nhuan = tong_doanh_thu - tong_chi_phi

  print(f"Tổng doanh thu: {tong_doanh_thu:,} VNĐ")
  print(f"Tổng chi phí: {tong_chi_phi:,} VNĐ")
  print(f"Lợi nhuận: {loi_nhuan:,} VNĐ")
  print(f"Số giao dịch: {so_giao_dich}")
  if tong_doanh_thu > 0:
    print(f"Tỷ lệ lợi nhuận: {(loi_nhuan/tong_doanh_thu)*100:.2f}%")
  print("="*50)

def bao_cao_nam(lst_data, nam):
  """Báo cáo doanh thu và chi phí theo năm"""
  tong_doanh_thu = 0
  tong_chi_phi = 0
  so_giao_dich = 0
  bao_cao_thang_data = {}

  print(f"\n=== BÁO CÁO NĂM {nam} ===")

  # Tổng hợp theo năm
  for item in lst_data:
    ngay_tao = item.ngay_tao if hasattr(item, 'ngay_tao') else item.__dict__.get('ngay_tao')
    if ngay_tao and ngay_tao.year == nam:
      doanh_thu = item.doanh_thu if hasattr(item, 'doanh_thu') else item.__dict__.get('doanh_thu', 0)
      chi_phi = item.chi_phi if hasattr(item, 'chi_phi') else item.__dict__.get('chi_phi', 0)

      tong_doanh_thu += doanh_thu
      tong_chi_phi += chi_phi
      so_giao_dich += 1

      # Thống kê theo tháng
      thang = ngay_tao.month
      if thang not in bao_cao_thang_data:
        bao_cao_thang_data[thang] = {'doanh_thu': 0, 'chi_phi': 0, 'giao_dich': 0}
      bao_cao_thang_data[thang]['doanh_thu'] += doanh_thu
      bao_cao_thang_data[thang]['chi_phi'] += chi_phi
      bao_cao_thang_data[thang]['giao_dich'] += 1

  loi_nhuan = tong_doanh_thu - tong_chi_phi

  print(f"Tổng doanh thu: {tong_doanh_thu:,} VNĐ")
  print(f"Tổng chi phí: {tong_chi_phi:,} VNĐ")
  print(f"Lợi nhuận: {loi_nhuan:,} VNĐ")
  print(f"Số giao dịch: {so_giao_dich}")
  if tong_doanh_thu > 0:
    print(f"Tỷ lệ lợi nhuận: {(loi_nhuan/tong_doanh_thu)*100:.2f}%")

  # Chi tiết theo tháng
  print(f"\nChi tiết theo tháng:")
  print(f"{'Tháng':<8} {'Doanh thu':<15} {'Chi phí':<15} {'Lợi nhuận':<15} {'Giao dịch':<10}")
  print("-" * 70)
  for thang in sorted(bao_cao_thang_data.keys()):
    data = bao_cao_thang_data[thang]
    loi_nhuan_thang = data['doanh_thu'] - data['chi_phi']
    print(f"{thang:<8} {data['doanh_thu']:<15,} {data['chi_phi']:<15,} {loi_nhuan_thang:<15,} {data['giao_dich']:<10}")
  print("="*60)

def xu_ly_report(analysis, lst_data):
  """Xử lý yêu cầu báo cáo"""
  report_type = analysis.get("report_type")

  if report_type == "thang":
    thang = analysis.get("period", datetime.now().month)
    nam = analysis.get("year", datetime.now().year)
    bao_cao_thang(lst_data, thang, nam)

  elif report_type == "quy":
    quy = analysis.get("period", (datetime.now().month - 1) // 3 + 1)
    nam = analysis.get("year", datetime.now().year)
    bao_cao_quy(lst_data, quy, nam)

  elif report_type == "nam":
    nam = analysis.get("year", datetime.now().year)
    bao_cao_nam(lst_data, nam)

  elif report_type == "ngay":
    # Báo cáo theo ngày (có thể mở rộng thêm)
    print("Tính năng báo cáo theo ngày sẽ được phát triển...")

  else:
    print("Loại báo cáo không được hỗ trợ")
    return False

  return True

error_key = 0
api_key_default = api_keys[0]
client = genai.Client(api_key=api_key_default)

while True:
  user_input = input("Nhập dữ liệu đầu vào để xử lý (hoặc 'exit' để thoát): ")
  if user_input.lower() == "exit":
      break

  try:
      repo_type = call_api("gemini-2.5-flash", prompt_type_input(user_input))
      clean_json = clean_text_json(repo_type.text)
      analysis = json.loads(clean_json)

      if analysis["type_input"] == "entry":
          try:
              repo = call_api("gemini-2.5-flash", write_prompt_text(user_input))
              clean_json = clean_text_json(repo.text)
              data = json.loads(clean_json)
              finan = FinanceRecord(0, doanh_thu=data["doanh_thu"], chi_phi=data["chi_phi"], ghi_chu=data["ghi_chu"], ngay_tao=format_strin_to_datetime("ngay_tao"))
              isOk = input("Xác nhận dữu liệu")
              if isOk == "ok":
                  lst_data.append(finan)
                  print("Dữ liệu đã được thêm thành công!")
              else:
                  print("Dữ liệu đã bị huỷ bỏ")
          except Exception as e:
              print(f"Không thể xử lý entry này: {e}")
      elif analysis["type_input"] == "report":
          xu_ly_report(analysis, lst_data)
      else:
        repo = call_api("gemini-2.5-flash", user_input + " Giải thích ngắn gọn")
        print(repo.text)
  except Exception as e:
      print(f"Lỗi khi xử lý input: {e}")
print("Dữ liệu sau khi xử lý:")
for item in lst_data:
  print(item.__dict__)