
--参考网址 URL: https://baike.baidu.com/item/%E8%B4%A7%E5%B8%81%E4%BB%A3%E7%A0%81/7467182?fr=aladdin
if not SYSTEM_CONF then SYSTEM_CONF = {} end

SYSTEM_CONF.coin_code = {
	Afghani = "AFA",
	Algerian_Dinar = "DZD",
	Antilles_Guilder = "ANG",
	Austria_Schilling = "ATS",
	Aruba_Florin = "AWF",
	--波斯尼亚和黑塞哥维那（Bosnia_and_Herzegovina_Convertible Mark）
	BHCM = "BAK",
	Bulgaria_Lev = "BGL",
	Brunei_Darussalam_Dollar = "BND",
	Bhutan_Rupee = "BTR",
	Canada_Dollar = "CAD",
	Switzerland_Franc = "CHF",
	Colombia_Peso = "COP",
	Cuba_Peso = "CUP",
	Britain_Pound = "GBP",
	Dominican_Republic_Peso = "DOP",
	Burma_Kyat = "MMK",
	Eritrea_Nakfa = "ERN",
	Ethiopia_Birr = "ETB",
	Finland_Markka = "FIM",
	China = "CNY",
	Ghana_Cedi = "GHC",
	Guinea_Franc = "GNF",
	Guyana_Dollar = "GYD",
	Croatia_Kuna = "HRK",
	Indonesia_Rupiah = "IDR",
	India_Rupee = "INR",
	Iceland_Krona = "ISK",
	Jamaica_Dollar = "JMD",
	Kenya_Shilling = "KES",
	--几内亚法郎(Equatorial Guinea CFA Franc)
	EG_CFA_Franc = "XAF",
	Kuwait_Dinar = "KWD",
	Lebanon_Pound = "LBP",
	Lesotho_Loti = "LSL",
	Latvia_Lat = "LVL",
	Moldova_Leu = "MDL",
	Gabon_CFA_Franc = "XAF",
	Macau_Pataca = "MOP",
	Mauritius_Rupee = "MUR",
	Mexico_Peso = "MXP",
	Mozambique_Metical = "MZM",
	Nicaragua_Cordoba_Oro = "NIO",
	Guinea_Franc = "GNF",
	Oman_Sul_Rial = "OMR",
	Philippines_Peso = "PHP",
	Paraguay_Guarani = "PYG",
	Russia_Ruble = "RUR",
	Sudan_Dinar = "SDD",
	Slovenia_Tolar = "SIT",
	Jordan_Dinar = "JOD",
	Swaziland_Lilangeni = "SZL",
	Turkmenistan_Manat = "TMM",
	Tanzania_Shilling = "TZS",
	Uruguay_Peso = "UYU",
	Venezuela_Bolivar = "VEB",
	Yemen_Rial = "YER",
	Zambia_Kwacha = "ZMK",
	Dirham = "AED",
	Andorra_French_Franc = "FRF",
	Angola_New_Kwanza = "AON",
	Australia_Dollar = "AUD",
	--安提瓜和巴布达岛东加勒比元(Antigua and Barbuda East Caribbean Dollar)
	Antigua_and_Barbuda_East_Caribbean_Dollar = "XCD",
	Barbados_Dollar = "BBD",
	Burundi_Franc = "BIF",
	Boliviano = "BOB",
	Botswana_Pula = "BWP",
	Benin_CFA_Franc = "XAF",
	Chile_Peso = "CLP",
	Costa_Rica_Colon = "CRC",
	Cape_Verde_Escudo = "CVE",
	Germany_Deutsche_Mark = "DEM",
	Burkina_Faso_CFA_Franc = "XAF",
	Estonia_Kroon = "EEK",
	Spain_Peseta = "ESP",
	Cameroon_CFA_Franc = "XAF",
	Fiji_Dollar = "FJD",
	Chad_CFA_Franc = "XAF",
	Gibraltar_Pound = "GIP",
	Greece_Drachma = "GRD",
	Hong_Kong_Dollar = "HKD",
	Haiti_Gourde = "HTG",
	Eire_Punt = "IEP",
	Iraq_Dinar = "IQD",
	Dutch_Guilder = "NLG",
	Jordan_Dinar = "JOD",
	El_Salvador_Colon = "SVC",
	Korea_Won = "KRW",
	Kazakstan_Tenge = "KZT",
	Sri_Lanka_Rupee = "LKR",
	Lithuania_Lita = "LTL",
	Libya_Dinar = "LYD",
	Malagasy_Franc = "MGF",
	Gambia_Dalasi = "GMD",
	Mauritania_Ouguiya = "MRO",
	Maldives_Rufiyaa = "MVR",
	Greenland_Danish_Krone = "DKK",
	Namibia_Dollar = "NAD",
	Guatemala_Quetzal = "GTQ",
	Nepalese_Rupee = "NPR",
	Panama_Balboa = "PAB",
	Pakistan_Rupee = "PKR",
	Qatar_Rial = "QAR",
	Rwanda_Franc = "RWF",
	Sweden_Krona = "SEK",
	Slovakia_Koruna = "SKK",
	Somalia_Shilling = "SOS",
	Thailand_Baht = "THB",
	Tunisia_Dinar = "TND",
	Turkey_Lira = "TRL",
	Ukraine_Hryvnia = "UAH",
	US_Dollar = "USD",
	Viet_Nam_Dong = "VND",
	Yugoslavia_New_Dinar = "YUN",
	Zimbabwe_Dollar = "ZWD",
	Albania_Lek = "ALL",
	Armenia_Dram = "AMD",
	Argentina_Peso = "ARP",
	Anguilla_East_Caribbean_Dollar = "XCD",
	Azerbaijan_Manat = "AZM",
	Belgium_Franc = "BEF",
	Bahamas_Dollar = "BSD",
	Brazilian_Real = "BRL",
	Belize_Dollar = "BZD",
	Congolese_Franc = "CDF",
	China_Yuan_Renminbi = "CNY",
	Czech_Republic_Koruna = "CZK",
	Cyprus_Pound = "CYP",
	Denmark_Krone = "DKK",
	Ecuador_Sucre = "ECS",
	Egypt_Pound = "EGP",
	Cambodia_Riel = "KHR",
	Euro = "EUR",
	France_Franc = "FRF",
	Georgia_Lari = "GEL",
	Gambia_Dalasi = "GMD",
	Guatemala_Quetzal = "GTQ",
	New_Zealand_Dollar = "NZD",
	Hungary_Forint = "HUF",
	Israel_Shekel = "ILS",
	Iran_Rial = "IRR",
	Italy_Lira = "ITL",
	Japan_Yen = "JPY",
	Korea_Won = "KPW",
	Ethiopian_Birr = "ETB",
	Laos_Kip = "LAK",
	Liberia_Dollar = "LRD",
	Luxembourg_Franc = "LUF",
	Morocco_Dirham = "MAD",
	Macedonia_Denar = "MKD",
	Mongolia_Tugrik = "MNT",
	Malta_Lira = "MTL",
	Greece_Drachma = "GRD",
	Malaysia_Ringgit = "MYR",
	Nigeria_Naira = "NGN",
	Norway_Krone = "NOK",
	New_Zealand_Dollar = "NZD",
	Peru_Nuevo_Sol = "PEN",
	Poland_Zloty = "PLZ",
	Romania_Leu = "ROL",
	Saudi_Arabia_Riyal = "SAR",
	Singapore_Dollar = "SGD",
	Sierra_Leone = "SLL",
	Syria_Pound = "SYP",
	Tajikistan_Ruble = "TJR",
	Latvia_Lat = "LVL",
	Taiwan_Dollar = "TWD",
	Uganda_Shilling = "UGX",
	Uzbekistan_Som = "Uzbekistan",
	Vanuatu_Vatu = "VUV",
	South_Africa_Rand = "ZAR",
	Nicaragua_Cordoba_Oro = "NIO",
	Tonga = "TOP"
}
