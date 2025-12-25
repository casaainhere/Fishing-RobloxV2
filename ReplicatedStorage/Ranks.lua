local module = {}

module.ranks = {
	{
		RankName = "Moderator",
		Usernames = {""},
		Userid = {8945072911,7636491359,5052687433},
		RankColor = Color3.fromRGB(255, 144, 144)
	},
	{
		RankName = "Head Admin",
		Usernames = {""},
		Userid = {8948988966},
		RankColor = Color3.fromRGB(255, 0, 0)
	},
	{
		RankName = "Admin",
		Usernames = {""},
		Userid = {},
		RankColor = Color3.fromRGB(255, 103, 89)
	},
	{
		RankName = "Content Creator",
		Usernames = {""},
		Userid = {8840108591},
		RankColor = Color3.fromRGB(100, 76, 173)
	},
	{
		RankName = "Owner",
		Usernames = {""},
		Userid = {8840108591},
		RankColor = Color3.fromRGB(255, 170, 0)
	},
	{
		RankName = "VIP",
		GamepassId = 1527526906, --ganti dengan id gamepass kalau ada gamepass vip
		RankColor = Color3.fromRGB(148, 112, 255)
	},
	-- Tambahan rank baru untuk member komunitas
	{
		RankName = "Member",
		GroupId = 707175213, --ganti dengan id group kalau ada group
		RankColor = Color3.fromRGB(15, 251, 231)
	},
}

module.defaultrank = {
	RankName = "GUEST",
	RankColor = Color3.fromRGB(126, 126, 126)
}

module.config = {
	VIPItems = {"OWNER","VIP","HEAD ADMIN","ADMIN","MODERATOR","CONTENT CREATOR","MEMBER"},
	Class = {"OWNER","HEAD ADMIN","ADMIN","MODERATOR","CONTENT CREATOR","VIP","MEMBER"}
}

return module
