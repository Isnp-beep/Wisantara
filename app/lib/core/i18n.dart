/// Terjemahan antarmuka: id, en, zh, ja, ko. Urutan: [id, en, zh, ja, ko].
class I18n {
  static String lang = 'id';
  static const codes = ['id', 'en', 'zh', 'ja', 'ko'];
  static const names = {
    'id': 'Bahasa Indonesia', 'en': 'English', 'zh': '中文', 'ja': '日本語', 'ko': '한국어',
  };

  static const _t = <String, List<String>>{
    'home': ['Beranda', 'Home', '首页', 'ホーム', '홈'],
    'explore': ['Jelajah', 'Explore', '探索', '探索', '탐색'],
    'community': ['Komunitas', 'Community', '社区', 'コミュニティ', '커뮤니티'],
    'orders': ['Pesanan', 'Orders', '订单', '注文', '주문'],
    'profile': ['Profil', 'Profile', '我的', 'プロフィール', '프로필'],
    'greeting': ['Halo', 'Hello', '你好', 'こんにちは', '안녕하세요'],
    'ask_ai': ['Mau liburan ke mana? Ketik budget & harimu', 'Where to? Type your budget & days', '想去哪里？输入预算和天数', 'どこへ行く？予算と日数を入力', '어디로 갈까요? 예산과 일수를 입력'],
    'popular': ['Populer', 'Popular', '热门', '人気', '인기'],
    'nearby': ['Terdekat', 'Nearby', '附近', '近く', '주변'],
    'map': ['Peta', 'Map', '地图', '地図', '지도'],
    'guides': ['Pemandu', 'Guides', '导游', 'ガイド', '가이드'],
    'planner': ['Rencana', 'Planner', '行程', 'プラン', '플래너'],
    'translate': ['Terjemah', 'Translate', '翻译', '翻訳', '번역'],
    'search_hint': ['Cari wisata, daerah…', 'Search places, regions…', '搜索景点、地区…', 'スポット・地域を検索…', '장소, 지역 검색…'],
    'all': ['Semua', 'All', '全部', 'すべて', '전체'],
    'nature': ['Alam', 'Nature', '自然', '自然', '자연'],
    'beach': ['Pantai', 'Beach', '海滩', 'ビーチ', '해변'],
    'culture': ['Budaya', 'Culture', '文化', '文化', '문화'],
    'history': ['Sejarah', 'History', '历史', '歴史', '역사'],
    'food': ['Kuliner', 'Food', '美食', 'グルメ', '음식'],
    'ticket': ['Tiket', 'Ticket', '门票', 'チケット', '티켓'],
    'book_now': ['Pesan sekarang', 'Book now', '立即预订', '今すぐ予約', '지금 예약'],
    'pay_now': ['Bayar sekarang', 'Pay now', '立即支付', '今すぐ支払う', '지금 결제'],
    'access': ['Akses & estimasi', 'Access & time', '交通与时间', 'アクセス', '교통'],
    'pros': ['Kelebihan', 'Pros', '优点', '長所', '장점'],
    'cons': ['Kekurangan', 'Cons', '缺点', '短所', '단점'],
    'equipment': ['Perlengkapan', 'Equipment', '装备', '持ち物', '준비물'],
    'eat_nearby': ['Makan di sekitar', 'Eat nearby', '附近美食', '周辺グルメ', '주변 식당'],
    'reviews': ['Ulasan', 'Reviews', '评价', 'レビュー', '리뷰'],
    'login': ['Masuk', 'Sign in', '登录', 'ログイン', '로그인'],
    'register': ['Daftar', 'Sign up', '注册', '新規登録', '가입'],
    'email': ['Email', 'Email', '邮箱', 'メール', '이메일'],
    'password': ['Kata sandi', 'Password', '密码', 'パスワード', '비밀번호'],
    'name': ['Nama lengkap', 'Full name', '姓名', '氏名', '이름'],
    'forgot': ['Lupa kata sandi?', 'Forgot password?', '忘记密码？', 'パスワードを忘れた？', '비밀번호 찾기'],
    'logout': ['Keluar', 'Sign out', '退出', 'ログアウト', '로그아웃'],
    'language': ['Bahasa', 'Language', '语言', '言語', '언어'],
    'notifications': ['Notifikasi', 'Notifications', '通知', '通知', '알림'],
    'save': ['Simpan', 'Save', '保存', '保存', '저장'],
    'cancel': ['Batal', 'Cancel', '取消', 'キャンセル', '취소'],
    'post': ['Posting', 'Post', '发布', '投稿', '게시'],
    'comment': ['Komentar', 'Comments', '评论', 'コメント', '댓글'],
    'following': ['Mengikuti', 'Following', '关注', 'フォロー中', '팔로잉'],
    'for_you': ['Untuk kamu', 'For you', '推荐', 'おすすめ', '추천'],
    'budget': ['Budget', 'Budget', '预算', '予算', '예산'],
    'days': ['Hari', 'Days', '天数', '日数', '일수'],
    'people': ['Orang', 'People', '人数', '人数', '인원'],
    'total': ['Total', 'Total', '合计', '合計', '합계'],
    'paid': ['Lunas', 'Paid', '已支付', '支払済み', '결제완료'],
    'pending': ['Belum bayar', 'Unpaid', '待支付', '未払い', '미결제'],
    'itinerary': ['Jadwal', 'Itinerary', '行程表', '日程', '일정'],
    'packing': ['Barang bawaan', 'Packing', '行李', '持ち物', '짐'],
    'expenses': ['Pengeluaran', 'Expenses', '支出', '支出', '지출'],
    'remaining': ['Sisa', 'Remaining', '剩余', '残り', '잔액'],
    'empty': ['Belum ada data', 'Nothing here yet', '暂无内容', 'まだありません', '아직 없습니다'],
    'retry': ['Coba lagi', 'Retry', '重试', '再試行', '다시 시도'],
  };

  static String t(String k) {
    final v = _t[k];
    if (v == null) return k;
    final i = codes.indexOf(lang);
    return v[i < 0 ? 0 : i];
  }
}

String t(String k) => I18n.t(k);
