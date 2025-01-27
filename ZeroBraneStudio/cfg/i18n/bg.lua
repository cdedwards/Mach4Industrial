return {
  [0] = function(c) return c == 1 and 1 or 2 end, -- plural
  ["%s event failed: %s"] = "%s събитие се провали: %s", -- src\editor\package.lua
  ["%s%% formatted..."] = "%s%% форматирано...", -- src\editor\print.lua
  ["%s%% loaded..."] = "%s%% заредено...", -- src\editor\commands.lua
  ["&About"] = "&За програмата", -- src\editor\menu_help.lua
  ["&Add Watch"] = "&Добавете изглед", -- src\editor\debugger.lua
  ["&Break"] = "&Прекратете", -- src\editor\menu_project.lua
  ["&Close Page"] = "&Затвори страницата", -- src\editor\gui.lua, src\editor\menu_file.lua
  ["&Community"] = "&Общество", -- src\editor\menu_help.lua
  ["&Compile"] = "&Компилирай", -- src\editor\menu_project.lua
  ["&Copy Value"] = "Копирай стойност", -- src\editor\debugger.lua
  ["&Copy"] = "&Копирай", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["&Default Layout"] = "&Вид по подразбиране", -- src\editor\menu_view.lua
  ["&Delete Watch"] = "&Изтрий изглед", -- src\editor\debugger.lua
  ["&Delete"] = "&Издрий", -- src\editor\filetree.lua
  ["&Documentation"] = "Документация", -- src\editor\menu_help.lua
  ["&Edit Project Directory"] = "&Редактиране проектната директория", -- src\editor\filetree.lua
  ["&Edit Value"] = "&Редактиране стойност", -- src\editor\debugger.lua
  ["&Edit Watch"] = "&Редактиране следене", -- src\editor\debugger.lua
  ["&Edit"] = "&Редакция", -- src\editor\menu_edit.lua
  ["&File"] = "&Файл", -- src\editor\menu_file.lua
  ["&Find"] = "&Намери", -- src\editor\menu_search.lua
  ["&Fold/Unfold All"] = "&Сгъни/Разгъни всички", -- src\editor\menu_edit.lua
  ["&Frequently Asked Questions"] = "&Често задавани въпроси", -- src\editor\menu_help.lua
  ["&Getting Started Guide"] = "&Как да започнем", -- src\editor\menu_help.lua
  ["&Help"] = "&Помощ", -- src\editor\menu_help.lua
  ["&New Directory"] = "&Нова директория", -- src\editor\filetree.lua
  ["&New"] = "&Създай", -- src\editor\menu_file.lua
  ["&Open..."] = "&Отвори...", -- src\editor\menu_file.lua
  ["&Output/Console Window"] = "&Изход/Конзолен прозорец", -- src\editor\menu_view.lua
  ["&Paste"] = "&Постави", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["&Print..."] = "Печат...", -- src\editor\print.lua
  ["&Project Page"] = "Страница на проекта", -- src\editor\menu_help.lua
  ["&Project"] = "&Проект", -- src\editor\menu_project.lua
  ["&Redo"] = "&Пренаправи", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["&Rename"] = "Преименовай", -- src\editor\filetree.lua
  ["&Replace"] = "&Замени", -- src\editor\menu_search.lua
  ["&Run"] = "&Пусни", -- src\editor\menu_project.lua
  ["&Save"] = "&Съхрани", -- src\editor\gui.lua, src\editor\menu_file.lua
  ["&Search"] = "&Търсене", -- src\editor\menu_search.lua
  ["&Select Command"] = "&Изберете команда", -- src\editor\gui.lua
  ["&Sort"] = "&Cортирай", -- src\editor\menu_edit.lua
  ["&Stack Window"] = "Стеков прозорец", -- src\editor\menu_view.lua
  ["&Start Debugger Server"] = "&Пусни дебъгер на сървъра", -- src\editor\menu_project.lua
  ["&Status Bar"] = "Панел на състоянието", -- src\editor\menu_view.lua
  ["&Tool Bar"] = "Панел за инструменти", -- src\editor\menu_view.lua
  ["&Tutorials"] = "&Обучителни материали", -- src\editor\menu_help.lua
  ["&Undo"] = "&Отмени", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["&View"] = "&Изглед", -- src\editor\menu_view.lua
  ["&Watch Window"] = "&Прозорец за изгледите", -- src\editor\menu_view.lua
  ["About %s"] = "За %s", -- src\editor\menu_help.lua
  ["Add To Scratchpad"] = "Добави в чернова", -- src\editor\editor.lua
  ["Add Watch Expression"] = "Добави израз", -- src\editor\editor.lua
  ["All files"] = "Всички файлове", -- src\editor\commands.lua
  ["Allow external process to start debugging"] = "Разреши външен процес са стартиране на дебъгер", -- src\editor\menu_project.lua
  ["Analyze the source code"] = "Анализирай изходния код", -- src\editor\inspect.lua
  ["Analyze"] = "Анализирай", -- src\editor\inspect.lua
  ["Auto Complete Identifiers"] = "Идентификатори за автозавършване", -- src\editor\menu_edit.lua
  ["Auto complete while typing"] = "Автозавършване по време на писане", -- src\editor\menu_edit.lua
  ["Binary file is shown as read-only as it is only partially loaded."] = "Двоичния файл се показва в режим за четене защото е частично зареден.", -- src\editor\commands.lua
  ["Bookmark"] = "Показалец", -- src\editor\menu_edit.lua
  ["Break execution at the next executed line of code"] = "Спри изпълнението на следващия изпълнен ред от кода", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Breakpoint"] = "Контролна точка", -- src\editor\menu_project.lua
  ["C&lear Console Window"] = "&Изчисти конзолния прозорец", -- src\editor\gui.lua
  ["C&lear Output Window"] = "&Изчисти изходния прозорец", -- src\editor\gui.lua, src\editor\menu_project.lua
  ["C&omment/Uncomment"] = "&Коментирай/Разкоментирай", -- src\editor\menu_edit.lua
  ["Can't evaluate the expression while the application is running."] = "Неможе да се пресметне стойността на израза докато приложението работи", -- src\editor\debugger.lua
  ["Can't open file '%s': %s"] = "Неможе да се отвори файла '%s': %s", -- src\editor\findreplace.lua, src\editor\package.lua, src\editor\inspect.lua, src\editor\outline.lua
  ["Can't process auto-recovery record; invalid format: %s."] = "Неможе да се преработи авотматично възстановения запис; невалиден формат: %s.", -- src\editor\commands.lua
  ["Can't replace in read-only text."] = "Неможе да се заменя текст във режим на четене.", -- src\editor\findreplace.lua
  ["Can't run the entry point script ('%s')."] = "Неможе да се пусне входен сприпт ('%s').", -- src\editor\debugger.lua
  ["Can't start debugger server at %s:%d: %s."] = "Неможе да се пусне сървърен дебъгер %s:%d: %s", -- src\editor\debugger.lua
  ["Can't start debugging for '%s'."] = "Неможе да се пусне дебъгер за '%s'.", -- src\editor\debugger.lua
  ["Can't start debugging session due to internal error '%s'."] = "Неможе да се стартира дебъг сесия поради вътрешна грешка '%s'.", -- src\editor\debugger.lua
  ["Can't start debugging without an opened file or with the current file not being saved."] = "Неможе да се стартира дебъг сесия без да е отворен файл или текущия да е запазен.", -- src\editor\debugger.lua
  ["Can't stop debugger server as it is not started."] = "Неможе да се спре сърварния дебъгер защото не е пуснат", -- src\editor\debugger.lua
  ["Cancelled by the user."] = "Отменено от потребителя.", -- src\editor\findreplace.lua
  ["Choose a directory to map"] = "Изберете диреклтория за добавяне", -- src\editor\filetree.lua
  ["Choose a project directory"] = "Изберете диреклтория за проекта", -- src\editor\toolbar.lua, src\editor\menu_project.lua, src\editor\filetree.lua
  ["Choose a search directory"] = "Изберете диреклтория за търсене", -- src\editor\findreplace.lua
  ["Choose..."] = "Изберете...", -- src\editor\findreplace.lua, src\editor\menu_project.lua, src\editor\filetree.lua
  ["Clear Breakpoints In File"] = "Изчисти Контролните точки във файла", -- src\editor\markers.lua, src\editor\menu_project.lua
  ["Clear Breakpoints In Project"] = "Почисти контролните точки за проекта", -- src\editor\markers.lua
  ["Clear Bookmarks In File"] = "Изчисти показалците във файла", -- src\editor\markers.lua, src\editor\menu_project.lua
  ["Clear Bookmarks In Project"] = "Почисти показалците за проекта", -- src\editor\markers.lua
  ["Clear Items"] = "Изчисти елементите", -- src\editor\findreplace.lua, src\editor\menu_file.lua
  ["Clear items from this list"] = "Изчисти елементите от този списък", -- src\editor\menu_file.lua
  ["Clear the output window before compiling or debugging"] = "Изчисти изходния прозорец преди компилация или дебъг", -- src\editor\menu_project.lua
  ["Close &Other Pages"] = "Затвори &останалите страници", -- src\editor\gui.lua
  ["Close A&ll Pages"] = "Затвори &всички страници", -- src\editor\gui.lua
  ["Close Search Results Pages"] = "Затвори страниците с резултати от търсенето", -- src\editor\gui.lua
  ["Close the current editor window"] = "Затвори текущия прозорец на редактора", -- src\editor\menu_file.lua
  ["Co&ntinue"] = "Пр&одължи", -- src\editor\menu_project.lua
  ["Col: %d"] = "Стб: %d", -- src\editor\editor.lua
  ["Command Line Parameters..."] = "Командни параметри...", -- src\editor\gui.lua, src\editor\menu_project.lua
  ["Command line parameters"] = "Параметри от командния ред", -- src\editor\menu_project.lua
  ["Comment or uncomment current or selected lines"] = "Коментирай или разкоментирай текущия или маркиран ред", -- src\editor\menu_edit.lua
  ["Compilation error"] = "Компилационна грешка", -- src\editor\commands.lua, src\editor\debugger.lua
  ["Compilation successful; %.0f%% success rate (%d/%d)."] = "Компилацията завършена успешно; процент успех: %.0f%% (%d/%d).", -- src\editor\commands.lua
  ["Compile the current file"] = "Компилирай текущия ред", -- src\editor\menu_project.lua
  ["Complete &Identifier"] = "Допълни &идентификатор", -- src\editor\menu_edit.lua
  ["Complete the current identifier"] = "Дополни текущ идентификатор", -- src\editor\menu_edit.lua
  ["Consider removing backslash from escape sequence '%s'."] = "Рассмотрите вариант удаления backslash из строки '%s'.", -- src\editor\commands.lua
  ["Copy Full Path"] = "Копирай Пълния Път", -- src\editor\gui.lua, src\editor\filetree.lua
  ["Copy selected text to clipboard"] = "Копирай маркирания текст в клипборда", -- src\editor\menu_edit.lua
  ["Correct &Indentation"] = "Коригирай отстъпа", -- src\editor\menu_edit.lua
  ["Couldn't activate file '%s' for debugging; continuing without it."] = "Невъзможно активирането на файл '%s' за дебъг; продължава се без него.", -- src\editor\debugger.lua
  ["Create an empty document"] = "Създай нов документ", -- src\editor\toolbar.lua, src\editor\menu_file.lua
  ["Cu&t"] = "Из&режи", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["Cut selected text to clipboard"] = "Изрежи маркирания текст в клипборда", -- src\editor\menu_edit.lua
  ["Debugger server started at %s:%d."] = "Сървърен дебъгер стартиран %s:%d.", -- src\editor\debugger.lua
  ["Debugger server stopped at %s:%d."] = "Сървърен дебъгер спрян %s:%d.", -- src\editor\debugger.lua
  ["Debugging session completed (%s)."] = "Дебъг сесия завършена (%s).", -- src\editor\debugger.lua
  ["Debugging session started in '%s'."] = "Дебъг сесия сатритрана '%s'.", -- src\editor\debugger.lua
  ["Debugging suspended at '%s:%s' (couldn't activate the file)."] = "Дебъга увизна '%s:%s' (невъзможно активирането на файл).", -- src\editor\debugger.lua
  ["Detach &Process"] = "Разкачи процес", -- src\editor\menu_project.lua
  ["Disable Indexing For '%s'"] = "Забрани Индексирането За '%s'", -- src\editor\outline.lua
  ["Do you want to delete '%s'?"] = "Искате ли да изтриете '%s'?", -- src\editor\filetree.lua
  ["Do you want to overwrite it?"] = "Искате ли да го презапишете?", -- src\editor\commands.lua
  ["Do you want to reload it?"] = "Искате ли да го презаредите?", -- src\editor\editor.lua
  ["Do you want to save the changes to '%s'?"] = "Изкате ли да запазите промените '%s'?", -- src\editor\commands.lua
  ["E&xit"] = "И&зход", -- src\editor\menu_file.lua
  ["Enable Indexing"] = "Разреши Индексирането", -- src\editor\outline.lua
  ["Enter Lua code and press Enter to run it."] = "Въведете Lua код и натиснете Ентър за да го изпълните.", -- src\editor\shellbox.lua
  ["Enter command line parameters"] = "Въведете параметри за командния ред", -- src\editor\menu_project.lua
  ["Enter replacement text"] = "Въведете текст за замяна", -- src\editor\editor.lua
  ["Error while loading API file: %s"] = "Грешка при зареждане на API: %s", -- src\editor\autocomplete.lua
  ["Error while loading configuration file: %s"] = "Грешка при зареждане на конфигурацията: %s", -- src\editor\style.lua
  ["Error while processing API file: %s"] = "Грешка при обработка на API: %s", -- src\editor\autocomplete.lua
  ["Error while processing configuration file: %s"] = "Грешка при обработка на конфигурация: %s", -- src\editor\style.lua
  ["Error"] = "Грешка", -- src\editor\commands.lua
  ["Evaluate In Console"] = "Изпълни в конзолата", -- src\editor\editor.lua
  ["Execute the current project/file and keep updating the code to see immediate results"] = "Изпълни текущия проект/файл и продължи да актуализираш кода за незабавни резултати", -- src\editor\menu_project.lua
  ["Execute the current project/file"] = "Изпълни текущия проект/файл", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Execution error"] = "Грешка при изпълнение", -- src\editor\debugger.lua
  ["Exit program"] = "Изход от програмата", -- src\editor\menu_file.lua
  ["File '%s' has been modified on disk."] = "Файла '%s' беше променен на диска.", -- src\editor\editor.lua
  ["File '%s' has more recent timestamp than restored '%s'; please review before saving."] = "Файла '%s' е модифицуран по-скоро от възстановения '%s'; прегледайте промените преди да съхраните.", -- src\editor\commands.lua
  ["File '%s' is missing and can't be recovered."] = "Файла '%s' липсва и неможе да бъде възстановен.", -- src\editor\commands.lua
  ["File '%s' no longer exists."] = "Файла '%s' вече не съществува.", -- src\editor\menu_file.lua, src\editor\editor.lua
  ["File already exists."] = "Файла вече существува.", -- src\editor\commands.lua
  ["File history"] = "Изтория на файловете", -- src\editor\menu_file.lua
  ["Find &In Files"] = "Намери &във файлове", -- src\editor\menu_search.lua
  ["Find &Next"] = "Намери &следващ", -- src\editor\menu_search.lua
  ["Find &Previous"] = "Намери &предишен", -- src\editor\menu_search.lua
  ["Find and insert library function"] = "Намери и внъкни библиотечна функция", -- src\editor\menu_search.lua
  ["Find and replace text in files"] = "Намери и замени текст във файлове", -- src\editor\menu_search.lua
  ["Find and replace text"] = "Намери и замени текст", -- src\editor\toolbar.lua, src\editor\menu_search.lua
  ["Find in files"] = "Намери във файлове", -- src\editor\toolbar.lua
  ["Find next"] = "Намери следващ", -- src\editor\toolbar.lua
  ["Find text in files"] = "Намери текст във файлове", -- src\editor\menu_search.lua
  ["Find text"] = "Намери текст", -- src\editor\toolbar.lua, src\editor\menu_search.lua
  ["Find the earlier text occurence"] = "Намери предишно съвпадение в текста", -- src\editor\menu_search.lua
  ["Find the next text occurrence"] = "Намери следващо съвпадение в текста", -- src\editor\menu_search.lua
  ["Fold or unfold all code folds"] = "Сгъни или разгъни всички блокове от кода", -- src\editor\menu_edit.lua
  ["Fold or unfold current line"] = "Сгъни или разгъни текущ ред", -- src\editor\menu_edit.lua
  ["Fold/Unfold Current &Line"] = "Сгъни/Разгъни текущ ред", -- src\editor\menu_edit.lua
  ["Formatting page %d..."] = "Форматиране страница %d...", -- src\editor\print.lua
  ["Found %d instance."] = {"Намерено %d съвпадение.", "Намерени %d совпадения."}, -- src\editor\findreplace.lua
  ["Found auto-recovery record and restored saved session."] = "Намерен авто-възвърнат запис и възстановена записана сесия.", -- src\editor\commands.lua
  ["Full &Screen"] = "На цял екр&ан", -- src\editor\menu_view.lua
  ["Go To Definition"] = "Отиди на дефиниция", -- src\editor\editor.lua
  ["Go To File..."] = "Отиди на файл...", -- src\editor\menu_search.lua
  ["Go To Line..."] = "Отиди на ред...", -- src\editor\menu_search.lua
  ["Go To Next Bookmark"] = "Отиди на следващ показалец", -- src\editor\menu_edit.lua
  ["Go To Next Breakpoint"] = "Отиди на следваща контролна точка", -- src\editor\menu_project.lua
  ["Go To Previous Bookmark"] = "Отиди на предишен показалец", -- src\editor\menu_edit.lua
  ["Go To Previous Breakpoint"] = "Отиди на предишна контролна точка", -- src\editor\menu_project.lua
  ["Go To Symbol..."] = "Отиди на символ...", -- src\editor\menu_search.lua
  ["Go to file"] = "Отиди на файл", -- src\editor\menu_search.lua
  ["Go to line"] = "Отиди на ред", -- src\editor\menu_search.lua
  ["Go to symbol"] = "Отиди на символ", -- src\editor\menu_search.lua
  ["Hide '.%s' Files"] = "Скрий '.%s' файловете", -- src\editor\filetree.lua
  ["INS"] = "ВСТ", -- src\editor\editor.lua
  ["Ignore and don't index symbols from files in the selected directory"] = "Игнорирай и не индексирай символи от файлове в избраната директория", -- src\editor\outline.lua
  ["Ignored error in debugger initialization code: %s."] = "Игнорирана грешка в инициализационния код на дебъгера: %s.", -- src\editor\debugger.lua
  ["Indexing %d files: '%s'..."] = "Индексиране %d файла: '%s'...", -- src\editor\outline.lua
  ["Indexing completed."] = "Индексиране завършено.", -- src\editor\outline.lua
  ["Insert Library Function..."] = "Вмъкни библиотечна функция...", -- src\editor\menu_search.lua
  ["Known Files"] = "Известни файлове", -- src\editor\commands.lua
  ["Ln: %d"] = "Лин: %d", -- src\editor\editor.lua
  ["Local console"] = "Локална конзола", -- src\editor\gui.lua, src\editor\shellbox.lua
  ["Lua &Interpreter"] = "Lua &интерпретатор", -- src\editor\menu_project.lua
  ["Map Directory..."] = "Добави директория...", -- src\editor\filetree.lua
  ["Mapped remote request for '%s' to '%s'."] = "Добавена отдалечена заявка за '%s' към '%s'.", -- src\editor\debugger.lua
  ["Markers Window"] = "Маркерен прозорец", -- src\editor\menu_view.lua
  ["Markers"] = "Маркери", -- src\editor\markers.lua
  ["Match case"] = "Съвпадение в случая", -- src\editor\toolbar.lua
  ["Match whole word"] = "Съвкадение на цяла дума", -- src\editor\toolbar.lua
  ["Mixed end-of-line encodings detected."] = "Различни кодировки за край на ред са открити.", -- src\editor\commands.lua
  ["Navigate"] = "Придвижване", -- src\editor\menu_search.lua
  ["New &File"] = "Нов &файл", -- src\editor\filetree.lua
  ["OVR"] = "ЗАМ", -- src\editor\editor.lua
  ["Open With Default Program"] = "Отвори с програма по подразбиране", -- src\editor\filetree.lua
  ["Open an existing document"] = "Отвори съществуващ документ", -- src\editor\toolbar.lua, src\editor\menu_file.lua
  ["Open file"] = "Отвори файл", -- src\editor\commands.lua
  ["Outline Window"] = "Структорен прозорец", -- src\editor\menu_view.lua
  ["Outline"] = "Структура", -- src\editor\outline.lua
  ["Output (running)"] = "Изход (работи)", -- src\editor\debugger.lua, src\editor\output.lua
  ["Output (suspended)"] = "Изход (преустановен)", -- src\editor\debugger.lua
  ["Output"] = "Изход", -- src\editor\debugger.lua, src\editor\output.lua, src\editor\gui.lua, src\editor\settings.lua
  ["Page Setup..."] = "Настройки на страница...", -- src\editor\print.lua
  ["Paste text from the clipboard"] = "Постави текст от клипборда", -- src\editor\menu_edit.lua
  ["Preferences"] = "Настройки", -- src\editor\menu_edit.lua
  ["Prepend '!' to force local execution."] = "Сложете '!' в началото за принудено локално изпълнение", -- src\editor\shellbox.lua
  ["Prepend '=' to show complex values on multiple lines."] = "Сложете '=' в началото за показване на комплексни стойности от мнжество редове.", -- src\editor\shellbox.lua
  ["Press cancel to abort."] = "Натиснете отказ за да прекратите.", -- src\editor\commands.lua
  ["Print the current document"] = "Печат на текущия документ", -- src\editor\print.lua
  ["Program '%s' started in '%s' (pid: %d)."] = "Програма '%s' пусната в '%s' (pid: %d).", -- src\editor\output.lua
  ["Program can't start because conflicting process is running as '%s'."] = "Програмата неможе да стартира защото конфликтен процес работи като '%s'.", -- src\editor\output.lua
  ["Program completed in %.2f seconds (pid: %d)."] = "Програмата завършена за %.2f секунди (pid: %d).", -- src\editor\output.lua
  ["Program starting as '%s'."] = "Програмата стартира като '%s'.", -- src\editor\output.lua
  ["Program stopped (pid: %d)."] = "Програмата завърши (pid: %d).", -- src\editor\debugger.lua
  ["Program unable to run as '%s'."] = "Програмата неможе да стартира като '%s'.", -- src\editor\output.lua
  ["Project Directory"] = "Проектна директория", -- src\editor\menu_project.lua, src\editor\filetree.lua
  ["Project history"] = "Проектна история", -- src\editor\menu_file.lua
  ["Project"] = "Проект", -- src\editor\filetree.lua
  ["Project/&FileTree Window"] = "Прозорец проект/&файлово дърво", -- src\editor\menu_view.lua
  ["Provide command line parameters"] = "Задай параметри от командния ред", -- src\editor\menu_project.lua
  ["Queued %d files to index."] = {"Поместен %d файл в индекса.","Поместени %d файлове в индекса."}, -- src\editor\menu_search.lua
  ["R/O"] = "R/O", -- src\editor\editor.lua
  ["R/W"] = "R/W", -- src\editor\editor.lua
  ["Re&place In Files"] = "За&мени във файлове", -- src\editor\menu_search.lua
  ["Re-indent selected lines"] = "Пре-встъпление на ибраните редове", -- src\editor\menu_edit.lua
  ["Reached end of selection and wrapped around."] = "Краят на избрания текст е достигнат и прехвърлен.", -- src\editor\findreplace.lua
  ["Reached end of text and wrapped around."] = "Краят на текста е достигнат и прехвърлен.", -- src\editor\findreplace.lua
  ["Recent Files"] = "Скорошни файлове", -- src\editor\menu_file.lua
  ["Recent Projects"] = "Скорошни проекти", -- src\editor\menu_file.lua
  ["Redo last edit undone"] = "Върни последната махната промяна", -- src\editor\menu_edit.lua
  ["Refresh Index"] = "Обнови индекс", -- src\editor\outline.lua
  ["Refresh Search Results"] = "Обнови търсени резултати", -- src\editor\gui.lua
  ["Refresh indexed symbols from files in the selected directory"] = "Обнови символни индекси от файловете в избрана диреклтория", -- src\editor\outline.lua
  ["Refresh"] = "Oбновление", -- src\editor\filetree.lua
  ["Refused a request to start a new debugging session as there is one in progress already."] = "Отказ от нова дебъг сесия поради наличие на такава.", -- src\editor\debugger.lua
  ["Regular expression"] = "Регулярен израз", -- src\editor\toolbar.lua
  ["Remote console"] = "Отдалечена конзола", -- src\editor\shellbox.lua
  ["Rename All Instances"] = "Преименовай всички инстанции", -- src\editor\editor.lua
  ["Replace All Selections"] = "Замени всички маркирания", -- src\editor\editor.lua
  ["Replace all"] = "Замени всички", -- src\editor\toolbar.lua
  ["Replace next instance"] = "Замени следващо съвпадение", -- src\editor\toolbar.lua
  ["Replaced %d instance."] = {"Заменено %d съвпадение.", "Заменени %d совпадения."}, -- src\editor\findreplace.lua
  ["Replaced an invalid UTF8 character with %s."] = "Некоректен символ UTF8 заменен с %s.", -- src\editor\commands.lua
  ["Reset to default layout"] = "Установи на разположение по подразбиране", -- src\editor\menu_view.lua
  ["Run As Scratchpad"] = "Пусни като чернова", -- src\editor\menu_project.lua
  ["Run To Cursor"] = "Пусни до курсора", -- src\editor\menu_project.lua, src\editor\editor.lua
  ["Run as Scratchpad"] = "Пусни като чернова", -- src\editor\toolbar.lua
  ["Run to cursor"] = "Пусни до курсора", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["S&top Debugging"] = "З&авърши дебъгване", -- src\editor\menu_project.lua
  ["S&top Process"] = "З&авърши процес", -- src\editor\menu_project.lua
  ["Save &As..."] = "Съхрани &като...", -- src\editor\gui.lua, src\editor\menu_file.lua
  ["Save A&ll"] = "Съхрани &всички", -- src\editor\menu_file.lua
  ["Save Changes?"] = "Съхрани промените?", -- src\editor\commands.lua
  ["Save all open documents"] = "Съхрани всички отворени документи", -- src\editor\toolbar.lua, src\editor\menu_file.lua
  ["Save file as"] = "Съхрани файл като", -- src\editor\commands.lua
  ["Save file?"] = "Съхрани файл?", -- src\editor\commands.lua
  ["Save the current document to a file with a new name"] = "Съхрани текущия документ в файл под ново име", -- src\editor\menu_file.lua
  ["Save the current document"] = "Съхрани текущия документ", -- src\editor\toolbar.lua, src\editor\menu_file.lua
  ["Saved auto-recover at %s."] = "Съхранен авто-възстановен в %s.", -- src\editor\commands.lua
  ["Scratchpad error"] = "Грешка в черновата", -- src\editor\debugger.lua
  ["Search direction"] = "Направление на търсене", -- src\editor\toolbar.lua
  ["Search in selection"] = "Търсене в маркиран текст", -- src\editor\toolbar.lua
  ["Search in subdirectories"] = "Търсене под-директории", -- src\editor\toolbar.lua
  ["Searching for '%s'."] = "Търсене за '%s'.", -- src\editor\findreplace.lua
  ["Sel: %d/%d"] = "Изб: %d/%d", -- src\editor\editor.lua
  ["Select &All"] = "Избери &всички", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["Select And Find Next"] = "Избери и намери следващо", -- src\editor\menu_search.lua
  ["Select And Find Previous"] = "Избери и намери предишно", -- src\editor\menu_search.lua
  ["Select all text in the editor"] = "Избери целия текст в редактора", -- src\editor\menu_edit.lua
  ["Select the word under cursor and find its next occurrence"] = "Избери думата под курсора и потърси следваща", -- src\editor\menu_search.lua
  ["Select the word under cursor and find its previous occurrence"] = "Избери думата под курсора и потърси предишна", -- src\editor\menu_search.lua
  ["Set As Start File"] = "Задай като начален файл", -- src\editor\filetree.lua
  ["Set From Current File"] = "Задай от текущия Файл", -- src\editor\menu_project.lua
  ["Set To Project Directory"] = "Задай като проектна директория", -- src\editor\findreplace.lua
  ["Set To Selected Directory"] = "Задай като избрана директория", -- src\editor\filetree.lua
  ["Set project directory from current file"] = "Задай проекта директория спрямо текущия файл", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Set project directory to the selected one"] = "Задай проекта директория спрямо избраната", -- src\editor\filetree.lua
  ["Set search directory"] = "Задай диреклтория за търсене", -- src\editor\toolbar.lua
  ["Set the interpreter to be used"] = "Задай използван интерпретатор", -- src\editor\menu_project.lua
  ["Set the project directory to be used"] = "Задай проектна диреклтория", -- src\editor\menu_project.lua, src\editor\filetree.lua
  ["Settings: System"] = "Настройки: Система", -- src\editor\menu_edit.lua
  ["Settings: User"] = "Настройки: Потребител", -- src\editor\menu_edit.lua
  ["Show &Tooltip"] = "Покажи &подсказка", -- src\editor\menu_edit.lua
  ["Show All Files"] = "Покажи всички файлове", -- src\editor\filetree.lua
  ["Show Hidden Files"] = "Покажи скрити файлове", -- src\editor\filetree.lua
  ["Show Location"] = "Покажи местонахождение", -- src\editor\gui.lua, src\editor\filetree.lua
  ["Show all files"] = "Покажи всички файлове", -- src\editor\filetree.lua
  ["Show context"] = "Покажи контекст", -- src\editor\toolbar.lua
  ["Show files previously hidden"] = "Покажи първоначално скритите", -- src\editor\filetree.lua
  ["Show multiple result windows"] = "Покажи прозорци за множествен резултат", -- src\editor\toolbar.lua
  ["Show tooltip for current position; place cursor after opening bracket of function"] = "Покажи подсказка на текуща позиция; премести курсора след отваряща скоба на функция", -- src\editor\menu_edit.lua
  ["Show/Hide the status bar"] = "Покажи/Скрий панел на състоянието", -- src\editor\menu_view.lua
  ["Show/Hide the toolbar"] = "Покажи/Скрий панел с инструменти", -- src\editor\menu_view.lua
  ["Sort By Name"] = "Сортирай по име", -- src\editor\outline.lua
  ["Sort selected lines"] = "Сортирай избреаните редове", -- src\editor\menu_edit.lua
  ["Source"] = "Изходен код", -- src\editor\menu_edit.lua
  ["Stack"] = "Стек", -- src\editor\debugger.lua
  ["Start &Debugging"] = "Начало &дебъг", -- src\editor\menu_project.lua
  ["Start or continue debugging"] = "Начало или продължение на дебъг", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Step &Into"] = "&Влез", -- src\editor\menu_project.lua
  ["Step &Over"] = "&Следваща стъпка", -- src\editor\menu_project.lua
  ["Step O&ut"] = "&Излез", -- src\editor\menu_project.lua
  ["Step into"] = "Влез във функция", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Step out of the current function"] = "Излез от текуща функция", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Step over"] = "Прескочи", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Stop debugging and continue running the process"] = "Завърши дебъг и продължи изпълнението на процеса", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Stop the currently running process"] = "Спри текущия работещ процес", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Switch to or from full screen mode"] = "Превключи от или към режим на цял екран", -- src\editor\menu_view.lua
  ["Symbol Index"] = "Символен индекс", -- src\editor\outline.lua
  ["Text not found."] = "Текста не е намерен.", -- src\editor\findreplace.lua
  ["The API file must be located in a subdirectory of the API directory."] = "API файлът трябва да се намира в под-директория на API директорията.", -- src\editor\autocomplete.lua
  ["Toggle Bookmark"] = "Превключи показалец", -- src\editor\markers.lua, src\editor\menu_edit.lua
  ["Toggle Breakpoint"] = "Превключи контролна точка", -- src\editor\markers.lua, src\editor\menu_project.lua
  ["Toggle bookmark"] = "Превключи показалец", -- src\editor\toolbar.lua, src\editor\menu_edit.lua, src\editor\markers.lua
  ["Toggle breakpoint"] = "Превключи контролна точка", -- src\editor\markers.lua, src\editor\toolbar.lua
  ["Tr&ace"] = "Тр&асировка", -- src\editor\menu_project.lua
  ["Trace execution showing each executed line"] = "Тресирай изпълнението показващо всеки изпълним файл", -- src\editor\menu_project.lua
  ["Unable to create directory '%s'."] = "Невъзможно създаването на директория '%s'.", -- src\editor\filetree.lua
  ["Unable to create file '%s'."] = "Невъзможно създаването на файл '%s'.", -- src\editor\filetree.lua
  ["Unable to delete directory '%s': %s"] = "Невъзможно изтриването на папки '%s': %s", -- src\editor\filetree.lua
  ["Unable to delete file '%s': %s"] = "Невъзможно изтриването на файл '%s': %s", -- src\editor\filetree.lua
  ["Unable to load file '%s'."] = "Невъзможно зареждането на файл '%s'.", -- src\editor\commands.lua
  ["Unable to rename file '%s'."] = "Невъзможно преименуването на файл '%s'.", -- src\editor\filetree.lua
  ["Unable to save file '%s': %s"] = "Невъзможно съхранението на файл '%s': %s", -- src\editor\commands.lua
  ["Unable to stop program (pid: %d), code %d."] = "Невъзможно спирането на програната (pid: %d), код %d.", -- src\editor\debugger.lua
  ["Undo last edit"] = "Отмяна на последно действие", -- src\editor\menu_edit.lua
  ["Unmap Directory"] = "Премахни диреклтория от списъка", -- src\editor\filetree.lua
  ["Unset '%s' As Start File"] = "Отмени '%s' като начален файл", -- src\editor\filetree.lua
  ["Updated %d file."] = {"Обновлен %d файл.", "Обновлени %d файла."}, -- src\editor\findreplace.lua
  ["Updating symbol index and settings..."] = "Актуализация символния индекс и настройки...", -- src\editor\outline.lua
  ["Use %s to close."] = "Използвайте %s да затворите.", -- src\editor\findreplace.lua
  ["Use '%s' to see full description."] = "Използвайте '%s' за видите пълното описание.", -- src\editor\editor.lua
  ["Use '%s' to show line endings and '%s' to convert them."] = "Използвайте '%s' за да се покажат кодировките за край на ред и '%s' да ги конвертирате.", -- src\editor\commands.lua
  ["Use 'clear' to clear the shell output and the history."] = "Използвайте команда 'clear' за почистване на конзолата и историята.", -- src\editor\shellbox.lua
  ["Use 'reset' to clear the environment."] = "Използвайте команда 'reset' за почистване на средата.", -- src\editor\shellbox.lua
  ["Use Shift-Enter for multiline code."] = "Използвайте Шифт-Ентър за многоредов код.", -- src\editor\shellbox.lua
  ["View the markers window"] = "Покажи прозорец за маркерите", -- src\editor\menu_view.lua
  ["View the outline window"] = "Покажи прозорец за очетание", -- src\editor\menu_view.lua
  ["View the output/console window"] = "Покажи прозорец за изход/цонзола", -- src\editor\menu_view.lua
  ["View the project/filetree window"] = "Покажи прозорец за проект/файлово дърво", -- src\editor\menu_view.lua
  ["View the stack window"] = "Покажи стеков прозорец", -- src\editor\toolbar.lua, src\editor\menu_view.lua
  ["View the watch window"] = "Покажи наблюдателен прозорец", -- src\editor\toolbar.lua, src\editor\menu_view.lua
  ["Watch"] = "Наблюдение", -- src\editor\debugger.lua
  ["Welcome to the interactive Lua interpreter."] = "Добре дошли в интерактивния Lua интерпретатор.", -- src\editor\shellbox.lua
  ["Wrap around"] = "Обгърни", -- src\editor\toolbar.lua
  ["You must save the program first."] = "Първо трябва да съхраните програмата.", -- src\editor\commands.lua
  ["Zoom In"] = "Увеличи", -- src\editor\menu_view.lua
  ["Zoom Out"] = "Намали", -- src\editor\menu_view.lua
  ["Zoom to 100%"] = "Установи на 100%", -- src\editor\menu_view.lua
  ["Zoom"] = "Установи мащаб", -- src\editor\menu_view.lua
  ["on line %d"] = "на ред %d", -- src\editor\debugger.lua, src\editor\editor.lua, src\editor\commands.lua
  ["traced %d instruction"] = {"трасирана %d инструкция", "трасирани %d инструкции"}, -- src\editor\debugger.lua
  ["unknown error"] = "неизвестна грешка", -- src\editor\debugger.lua
}
