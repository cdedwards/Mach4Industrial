-----------------------------------------------------------------------------
-- Name:        int18n
-- Author:      Steve Murphree
-- Modified by:
-- Created:     05/20/2020
-- Copyright:   (c) 2020 Newfangled Solutions. All rights reserved.
-- License:     BSD (Free as in REALLY free!)
-- Synopsis:    Uses wxTranslations from wxLua instead of GNU Gettext for NLS.
-----------------------------------------------------------------------------

local int18n = {
	domain = nil,
	tranlation = nil
	}

function int18n.Translate(str)
	str = tostring(str)
	if (wx.wxTranslations == nil) then
		return str
	end
	if (int18n.domain == nil) then 
		return wx.wxGetTranslation(str)
	end
	return wx.wxGetTranslation(str, domain)
end

function int18n.SetDomain(domain)
	int18n.domain = domain
end

function int18n.SetLanguage(langId)
	if (wx.wxTranslations == nil) then
		return
	end
	int18n.tranlation:SetLanguage(langId)
end

function int18n.AddCatalog(catalog, langId)
	if (wx.wxTranslations == nil) then
		return
	end
	langId = langId or wx.wxLANGUAGE_ENGLISH
	int18n.tranlation:AddCatalog(catalog, langId)
end

function _(text)
	if (wx.wxTranslations == nil) then 
		text = tostring(text)
		return text
	end
	return int18n.Translate(text)
end

function int18n.AddCatalogLookupPathPrefix(_prefix)
	if (wx.wxTranslations == nil) then 
		return
	end
	wx.wxFileTranslationsLoader.AddCatalogLookupPathPrefix(_prefix);
end

if ((wx.wxTranslations ~= nil) and (int18n.tranlation == nil)) then 
	int18n.tranlation = wx.wxTranslations()
	int18n.tranlation:SetLanguage(wx.wxLANGUAGE_ENGLISH_US)
	wx.wxTranslations.Set(int18n.tranlation)
end

return int18n
