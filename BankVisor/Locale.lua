local ADDON, ns = ...

ns.LANGS = {
    { code = "auto" },
    { code = "esES", name = "Español" },
    { code = "enUS", name = "English" },
    { code = "ptBR", name = "Português" },
    { code = "frFR", name = "Français" },
    { code = "deDE", name = "Deutsch" },
}

local strings = {}

strings.enUS = {
    LANG_AUTO = "Automatic",
    TITLE = "Bank Visor",
    TAB_BANK = "Bank",
    TAB_GUILD = "Guild",
    SEARCH = "Search",
    NO_DATA_BANK = "No data: open your bank in a capital city.",
    NO_DATA_GUILD = "No data: open the guild bank.",
    NO_DATA_TAB = "No data for this tab: view it in the guild bank.",
    NO_GUILD = "This character has no guild.",
    GUILD_TAB = "Tab %d",
    UPDATED = "Updated: %s",
    SLOTS_USED = "%d/%d slots used",
    MATCHES = "%d matches",
    DATE_FORMAT = "%m/%d/%Y %H:%M",
    MINIMAP_TIP = "Click: open - Drag: move",
    UI_UNAVAILABLE = "the interface is not available.",
}

strings.esES = {
    LANG_AUTO = "Automático",
    TITLE = "Bank Visor",
    TAB_BANK = "Banco",
    TAB_GUILD = "Gremio",
    SEARCH = "Buscar",
    NO_DATA_BANK = "Sin datos: abre tu banco en una capital.",
    NO_DATA_GUILD = "Sin datos: abre el banco del gremio.",
    NO_DATA_TAB = "Sin datos de esta pestaña: visítala en el banco del gremio.",
    NO_GUILD = "Este personaje no tiene gremio.",
    GUILD_TAB = "Pestaña %d",
    UPDATED = "Actualizado: %s",
    SLOTS_USED = "%d/%d ranuras ocupadas",
    MATCHES = "%d coincidencias",
    DATE_FORMAT = "%d/%m/%Y %H:%M",
    MINIMAP_TIP = "Clic: abrir - Arrastrar: mover",
    UI_UNAVAILABLE = "la interfaz no está disponible.",
}

strings.ptBR = {
    LANG_AUTO = "Automático",
    TAB_BANK = "Banco",
    TAB_GUILD = "Guilda",
    SEARCH = "Buscar",
    NO_DATA_BANK = "Sem dados: abra seu banco em uma capital.",
    NO_DATA_GUILD = "Sem dados: abra o banco da guilda.",
    NO_DATA_TAB = "Sem dados desta aba: visite-a no banco da guilda.",
    NO_GUILD = "Este personagem não tem guilda.",
    GUILD_TAB = "Aba %d",
    UPDATED = "Atualizado: %s",
    SLOTS_USED = "%d/%d espaços ocupados",
    MATCHES = "%d resultados",
    DATE_FORMAT = "%d/%m/%Y %H:%M",
    MINIMAP_TIP = "Clique: abrir - Arrastar: mover",
    UI_UNAVAILABLE = "a interface não está disponível.",
}

strings.frFR = {
    LANG_AUTO = "Automatique",
    TAB_BANK = "Banque",
    TAB_GUILD = "Guilde",
    SEARCH = "Rechercher",
    NO_DATA_BANK = "Aucune donnée : ouvrez votre banque dans une capitale.",
    NO_DATA_GUILD = "Aucune donnée : ouvrez la banque de guilde.",
    NO_DATA_TAB = "Aucune donnée pour cet onglet : consultez-le dans la banque de guilde.",
    NO_GUILD = "Ce personnage n'a pas de guilde.",
    GUILD_TAB = "Onglet %d",
    UPDATED = "Mis à jour : %s",
    SLOTS_USED = "%d/%d emplacements occupés",
    MATCHES = "%d résultats",
    DATE_FORMAT = "%d/%m/%Y %H:%M",
    MINIMAP_TIP = "Clic : ouvrir - Glisser : déplacer",
    UI_UNAVAILABLE = "l'interface n'est pas disponible.",
}

strings.deDE = {
    LANG_AUTO = "Automatisch",
    TAB_BANK = "Bank",
    TAB_GUILD = "Gilde",
    SEARCH = "Suchen",
    NO_DATA_BANK = "Keine Daten: Öffne deine Bank in einer Hauptstadt.",
    NO_DATA_GUILD = "Keine Daten: Öffne die Gildenbank.",
    NO_DATA_TAB = "Keine Daten für diesen Reiter: Sieh ihn in der Gildenbank an.",
    NO_GUILD = "Dieser Charakter hat keine Gilde.",
    GUILD_TAB = "Reiter %d",
    UPDATED = "Aktualisiert: %s",
    SLOTS_USED = "%d/%d Plätze belegt",
    MATCHES = "%d Treffer",
    DATE_FORMAT = "%d/%m/%Y %H:%M",
    MINIMAP_TIP = "Klick: Öffnen - Ziehen: Verschieben",
    UI_UNAVAILABLE = "die Oberfläche ist nicht verfügbar.",
}

local CLIENT_MAP = {
    esES = "esES", esMX = "esES",
    enUS = "enUS", enGB = "enUS",
    ptBR = "ptBR", ptPT = "ptBR",
    frFR = "frFR",
    deDE = "deDE",
}

function ns.CurrentLang()
    local lang = ns.DB and ns.DB().lang
    if lang == nil or lang == "auto" then
        local loc = GetLocale and GetLocale() or "enUS"
        return CLIENT_MAP[loc] or "enUS"
    end
    if not strings[lang] then return "enUS" end
    return lang
end

function ns.T(key, ...)
    local lang = strings[ns.CurrentLang()]
    local s = (lang and lang[key]) or strings.enUS[key] or key
    if select("#", ...) > 0 then
        local ok, res = pcall(string.format, s, ...)
        if ok then return res end
    end
    return s
end

function ns.SetLang(code)
    ns.DB().lang = code
    if ns.UI and ns.UI.ApplyLanguage then
        ns.UI.ApplyLanguage()
    end
end
