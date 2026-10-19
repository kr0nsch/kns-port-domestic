// Назначение: источник монотонного времени. Все задержки библиотеки берут время отсюда:
//             по умолчанию — FB_SystemTime (оператор LTIME()), в тестах — FB_FakeTime.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_SystemTime.md
INTERFACE I_TimeSource
