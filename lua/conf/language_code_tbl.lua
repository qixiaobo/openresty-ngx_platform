
--[[
网站URL: https://blog.csdn.net/u010586698/article/details/56673379
	key: 语言国家吗
	val：表 {
			语言,
			英文名称,
			中文名称
		}
]]

if not SYSTEM_CONF then SYSTEM_CONF = {} end

SYSTEM_CONF.language_code = {
	ar_IL =	{
				Code = "ar_IL",
				Language = "العربية",
				English_Name = "Arabic(Israel)",
				Chinese_Name = "阿拉伯语(以色列)"
			},
	ar_EG =	{
				Code = "ar_EG",
				Language = "العربية",
				English_Name = "Arabic(Egypt)",
				Chinese_Name = "阿拉伯语(埃及)"
			},

	zh_CN =	{
				Code = "zh_CN",
				Language = "中文",
				English_Name = "Chinese Simplified ",
				Chinese_Name = "中文简体"
			},
	zh_TW =	{
				Code = "zh_TW",
				Language = "中文",
				English_Name = "Chinese Tradition",
				Chinese_Name = "中文繁体"
			},
	zh_HK =	{
				Code = "zh_HK",
				Language = "中文",
				English_Name = "Chinese",
				Chinese_Name = "中文(香港)"
			},

	nl_NL =	{
				Code = "nl_NL",
				Language = "Nederlands",
				English_Name = "Dutch (Netherlands)",
				Chinese_Name = "荷兰语"
			},
	nl_BE =	{
				Code = "nl_BE",
				Language = "Nederlands",
				English_Name = "Dutch (Netherlands)",
				Chinese_Name = "荷兰语(比利时)"
			},

	en_US =	{
				Code = "en_US",
				Language = "English",
				English_Name = "English(United States)",
				Chinese_Name = "英语(美国)"
			},
	en_AU =	{
				Code = "en_AU",
				Language = "English",
				English_Name = "English(Australia)",
				Chinese_Name = "英语(澳大利亚)"
			},
	en_CA =	{
				Code = "en_CA",
				Language = "English",
				English_Name = "English(Canada)",
				Chinese_Name = "英语(加拿大)"
			},
	en_IN =	{
				Code = "en_IN",
				Language = "English",
				English_Name = "English(India)",
				Chinese_Name = "英语(印度)"
			},
	en_IE =	{
				Code = "en_IE",
				Language = "English",
				English_Name = "English(Ireland)",
				Chinese_Name = "英语(爱尔兰)"
			},
	en_NZ =	{
				Language = "English",
				English_Name = "English(New Zealand)",
				Chinese_Name = "英语(新西兰)"
			},
	en_SG =	{
				Code = "en_SG",
				Language = "English",
				English_Name = "English(Singapore)",
				Chinese_Name = "英语(新加波)"
			},
	en_ZA =	{
				Code = "en_ZA",
				Language = "English",
				English_Name = "English(South Africa)",
				Chinese_Name = "英语(南非)"
			},
	en_GB =	{
				Code = "en_GB",
				Language = "English",
				English_Name = "English(United Kingdom)",
				Chinese_Name = "英语(英国)"
			},

	fr_FR =	{
				Language = "Français",
				English_Name = "French",
				Chinese_Name = "法语"
			},
	fr_BE =	{
				Code = "fr_BE",
				Language = "Français",
				English_Name = "French",
				Chinese_Name = "法语(比利时)"
			},
	fr_CA =	{
				Code = "fr_CA",
				Language = "Français",
				English_Name = "French",
				Chinese_Name = "法语(加拿大)"
			},
	fr_CH =	{
				Code = "fr_CH",
				Language = "Français",
				English_Name = "French",
				Chinese_Name = "法语(瑞士)"
			},	

	de_DE =	{
				Code = "de_DE",
				Language = "Deutsch",
				English_Name = "German",
				Chinese_Name = "德语"
			},
	de_LI =	{
				Code = "de_LI",
				Language = "Deutsch",
				English_Name = "German",
				Chinese_Name = "德语(列支敦斯登)"
			},
	de_AT =	{
				Code = "de_AT",
				Language = "Deutsch",
				English_Name = "German",
				Chinese_Name = "德语(奥地利)"
			},
	de_CH =	{
				Code = "de_CH",
				Language = "Deutsch",
				English_Name = "German",
				Chinese_Name = "德语(瑞士)"
			},
	
	it_IT =	{
				Code = "it_IT",
				Language = "Italiano",
				English_Name = "Italian",
				Chinese_Name = "意大利语"
			},
	it_CH =	{
				Code = "it_CH",
				Language = "Italiano",
				English_Name = "Italian",
				Chinese_Name = "意大利语(瑞士)"
			},

	pt_BR =	{
				Code = "pt_BR",
				Language = "Protuguês",
				English_Name = "Portuguese",
				Chinese_Name = "葡萄牙语（巴西"
			},
	pt_PT =	{
				Code = "pt_PT",
				Language = "Protuguês",
				English_Name = "Portuguese",
				Chinese_Name = "葡萄牙语"
			},

	es_ES =	{
				Code = "es_ES",
				Language = "Español",
				English_Name = "Spanish",
				Chinese_Name = "西班牙语"
			},
	es_US =	{
				Code = "es_US",
				Language = "Español",
				English_Name = "Spanish",
				Chinese_Name = "西班牙语(美国)"
			},

	bn_BD =	{
				Code = "bn_BD",
				Language = "বাংলা",
				English_Name = "Bengali",
				Chinese_Name = "孟加拉语"
			},
	bn_IN =	{
				Code = "bn_IN",
				Language = "বাংলা",
				English_Name = "Bengali",
				Chinese_Name = "孟加拉语(印度)"
			},

	hr_HR =	{
				Code = "hr_HR",
				Language = "hrvatski",
				English_Name = "Croatian",
				Chinese_Name = "克罗地亚语"
			},

	cs_CZ =	{
				Code = "cs_CZ",
				Language = "čeština",
				English_Name = "Czech",
				Chinese_Name = "捷克语"
			},

	da_DK =	{
				Code = "da_DK",
				Language = "Dansk",
				English_Name = "Danish",
				Chinese_Name = "丹麦语"
			},

	el_GR =	{
				Code = "el_GR",
				Language = "ελληνικά",
				English_Name = "Greek",
				Chinese_Name = "希腊语"
			},

	he_IL =	{
				Code = "he_IL",
				Language = "עברית",
				English_Name = "Hebrew",
				Chinese_Name = "希伯来语(以色列)"
			},
	iw_IL =	{
				Code = "iw_IL",
				Language = "עברית",
				English_Name = "Hebrew",
				Chinese_Name = "希伯来语(以色列)"
			},

	hi_IN =	{
				Code = "hi_IN",
				Language = "हिंदी",
				English_Name = "Hindi",
				Chinese_Name = "印度语"
			},

	hu_HU =	{
				Code = "hu_HU",
				Language = "Magyar",
				English_Name = "Hungarian",
				Chinese_Name = "匈牙利语"
			},

	in_ID =	{
				Code = "in_ID",
				Language = "Bahasa Indonesia",
				English_Name = "Indonesian",
				Chinese_Name = "印度尼西亚语"
			},

	ja_JP =	{
				Code = "ja_JP",
				Language = "日本語の言語",
				English_Name = "Japanese",
				Chinese_Name = "日语"
			},

	ko_KR =	{
				Code = "ko_KR",
				Language = "한국의",
				English_Name = "Korean",
				Chinese_Name = "韩语（朝鲜语)"
			},

	ms_MY =	{
				Code = "ms_MY",
				Language = "Bahasa Melayu",
				English_Name = "Malay",
				Chinese_Name = "马来语"
			},

	fa_IR =	{
				Code = "fa_IR",
				Language = "فارسی",
				English_Name = "Perisan",
				Chinese_Name = "波斯语"
			},

	pl_PL =	{
				Code = "pl_PL",
				Language = "Polski",
				English_Name = "Polish",
				Chinese_Name = "波兰语"
			},

	ro_RO =	{
				Code = "ro_RO",
				Language = "româna",
				English_Name = "Romanian",
				Chinese_Name = "罗马尼亚语"
			},

	ru_RU =	{
				Code = "ru_RU",
				Language = "Русский",
				English_Name = "Russian",
				Chinese_Name = "俄罗斯语"
			},

	sr_RS =	{
				Code = "sr_RS",
				Language = "српски",
				English_Name = "Serbian",
				Chinese_Name = "塞尔维亚语"
			},

	sv_SE =	{
				Code = "sv_SE",
				Language = "Svenska",
				English_Name = "Swedish",
				Chinese_Name = "瑞典语"
			},

	th_TH =	{
				Code = "th_TH",
				Language = "ไทย",
				English_Name = "Thai",
				Chinese_Name = "泰语	"
			},

	tr_TR =	{
				Code = "tr_TR",
				Language = "Türkçe",
				English_Name = "Turkey",
				Chinese_Name = "土耳其语	"
			},

	ur_PK =	{
				Code = "ur_PK",
				Language = "اردو",
				English_Name = "Urdu",
				Chinese_Name = "乌尔都语"
			},

	vi_VN =	{
				Code = "vi_VN",
				Language = "tiếng việt",
				English_Name = "Vietnamese",
				Chinese_Name = "越南语"
			},

	ca_ES =	{
				Code = "ca_ES",
				Language = "catalá",
				English_Name = "Catalan",
				Chinese_Name = "加泰隆语(西班牙)"
			},

	lv_LV =	{
				Code = "lv_LV",
				Language = "latviešu",
				English_Name = "Latviesu",
				Chinese_Name = "拉脱维亚语"
			},

	lt_LT =	{
				Code = "lt_LT",
				Language = "Lietuvių",
				English_Name = "Lithuanian",
				Chinese_Name = "立陶宛语"
			},

	nb_NO =	{
				Code = "nb_NO",
				Language = "Norsk bokmal",
				English_Name = "Norwegian",
				Chinese_Name = "挪威语"
			},	

	sk_SK =	{
				Code = "sk_SK",
				Language = "Slovenčina",
				English_Name = "slovencina",
				Chinese_Name = "斯洛伐克语"
			},

	sl_SI =	{
				Code = "sl_SI",
				Language = "Slovenščina",
				English_Name = "Slovenian",
				Chinese_Name = "斯洛文尼亚语"
			},	

	bg_BG =	{
				Code = "bg_BG",
				Language = "български",
				English_Name = "bulgarian",
				Chinese_Name = "保加利亚语"
			},	

	uk_UA =	{
				Code = "uk_UA",
				Language = "українська",
				English_Name = "Ukrainian",
				Chinese_Name = "乌克兰语"
			},

	tl_PH =	{
				Code = "tl_PH",
				Language = "Tagalog",
				English_Name = "Filipino",
				Chinese_Name = "菲律宾语"
			},

	fi_FI =	{
				Code = "fi_FI",
				Language = "Suomi",
				English_Name = "Finnish",
				Chinese_Name = "芬兰语"
			},

	af_ZA =	{
				Code = "af_ZA",
				Language = "Afrikaans",
				English_Name = "Afrikaans",
				Chinese_Name = "南非语"
			},

	rm_CH =	{
				Code = "rm_CH",
				Language = "Rumantsch",
				English_Name = "Romansh",
				Chinese_Name = "罗曼什语(瑞士)"
			},

	my_ZG =	{
				Code = "my_ZG",
				Language = "ဗမာ",
				English_Name = "Burmese(Zawgyi)",
				Chinese_Name = "缅甸语(民间)"
			},
	my_MM =	{
				Code = "my_MM",
				Language = "ဗမာ",
				English_Name = "Burmese(Paduak)",
				Chinese_Name = "缅甸语(官方)"
			},

	km_KH =	{
				Code = "km_KH",
				Language = "ខ្មែរ",
				English_Name = "Khmer",
				Chinese_Name = "柬埔寨语"
			},

	am_ET =	{
				Code = "am_ET",
				Language = "አማርኛ",
				English_Name = "Amharic",
				Chinese_Name = "阿姆哈拉语(埃塞俄比亚)"
			},

	be_BY =	{
				Code = "be_BY",
				Language = "беларуская",
				English_Name = "Belarusian",
				Chinese_Name = "白俄罗斯语"
			},

	et_EE =	{
				Code = "et_EE",
				Language = "eesti",
				English_Name = "Estonian",
				Chinese_Name = "爱沙尼亚语"
			},

	sw_TZ =	{
				Code = "sw_TZ",
				Language = "Kiswahili",
				English_Name = "Swahili",
				Chinese_Name = "斯瓦希里语(坦桑尼亚)"
			},

	zu_ZA =	{
				Code = "zu_ZA",
				Language = "isiZulu",
				English_Name = "Zulu",
				Chinese_Name = "祖鲁语(南非)"
			},

	az_AZ =	{
				Code = "az_AZ",
				Language = "azərbaycanca",
				English_Name = "Azerbaijani",
				Chinese_Name = "阿塞拜疆语"
			},

	hy_AM =	{
				Code = "hy_AM",
				Language = "Հայերէն",
				English_Name = "Armenian",
				Chinese_Name = "亚美尼亚语(亚美尼亚)"
			},

	ka_GE =	{
				Code = "ka_GE",
				Language = "ქართული",
				English_Name = "Georgian",
				Chinese_Name = "格鲁吉亚语(格鲁吉亚)"
			},

	lo_LA =	{
				Code = "lo_LA",
				Language = "ລາວ",
				English_Name = "Laotian",
				Chinese_Name = "老挝语(老挝)"
			},

	mn_MN =	{
				Code = "mn_MN",
				Language = "Монгол",
				English_Name = "Mongolian",
				Chinese_Name = "蒙古语"
			},

	ne_NP =	{
				Code = "ne_NP",
				Language = "नेपाली",
				English_Name = "Nepali",
				Chinese_Name = "尼泊尔语"
			},

	kk_KZ =	{
				Code = "kk_KZ",
				Language = "қазақ тілі",
				English_Name = "Kazakh",
				Chinese_Name = "哈萨克语"
			},

	gl_rES ={
				Code = "gl-rES",
				Language = "Galego",
				English_Name = "Galician",
				Chinese_Name = "加利西亚语"
			},

	is_rIS ={
				Code = "is-rIS",
				Language = "íslenska",
				English_Name = "Icelandic",
				Chinese_Name = "冰岛语"
			},

	kn_rIN ={
				Code = "kn-rIN",
				Language = "ಕನ್ನಡ",
				English_Name = "Kannada",
				Chinese_Name = "坎纳达语"
			},

	ky_rKG ={
				Code = "ky-rKG",
				--кыргыз тили; قىرعىز تىلى
				Language = "кыргыз тили",
				English_Name = "Kyrgyz",
				Chinese_Name = "吉尔吉斯语"
			},

	ml_rIN ={
				Code = "ml-rIN",
				Language = "മലയാളം",
				English_Name = "Malayalam",
				Chinese_Name = "马拉亚拉姆语"
			},

	mr_rIN ={
				Code = "mr-rIN",
				Language = "मराठी",
				English_Name = "Marathi",
				Chinese_Name = "马拉提语/马拉地语"
			},

	ta_rIN ={
				Code = "ta-rIN",
				Language = "தமிழ்",
				English_Name = "Tamil",
				Chinese_Name = "泰米尔语 "
			},

	mk_rMK ={
				Code = "mk-rMK",
				Language = "македонски јазик",
				English_Name = "Macedonian",
				Chinese_Name = "马其顿语"
			},

	te_rIN ={
				Code = "te-rIN",
				Language = "తెలుగు",
				English_Name = "Telugu",
				Chinese_Name = "泰卢固语"
			},

	uz_rUZ ={
				Code = "uz-rUZ",
				Language = "Ўзбек тили",
				English_Name = "Uzbek",
				Chinese_Name = "乌兹别克语"
			},

	eu_rES	 ={
				Code = "eu-rES",
				Language = "Euskara",
				English_Name = "Basque",
				Chinese_Name = "巴斯克语"
			},

	si_LK	 ={
				Code = "si_LK",
				Language = "සිංහල",
				English_Name = "Sinhala",
				Chinese_Name = "僧加罗语(斯里兰卡)"
			},

}