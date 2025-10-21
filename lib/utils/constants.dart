const String startResponse = 'Hola, ¿qué acción deseas realizar hoy? Si necesitas más información, escribe /help.';

const String webConversationName = 'newEditScraping';

const String timeConversationName = 'editFrecuency';

const String deleteConversationName = 'deleteScraping';

const String emptyConversationName = 'emptyScraping';

const String helpResponse = '''
/start: Muestra las opciones de inicio.\n
/web: Crea o edita la web ingresada.\n
/time: Modifica la frecuencia en minutos en que se realiza la búsqueda.\n
/delete: Elimina la web ingresada.\n
/help: Muestra los comandos disponibles.
''';

const String errorResponse = 'Lo siento, algo ha salido mal.';

const String webButtonText = 'Crear/Editar Web Scraping';

const String timeButtonText = 'Cambiar frecuencia de notificaciones';

const String deleteButtonText = 'Eliminar Web Scraping';

const String backToStart = 'Para volver a ver las opciones de inicio, ingresa /start.';

const String timeoutException = 'Lo siento, el tiempo de espera se ha agotado.';

const String urlRegex = r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)';

const String askUrl = '¿Cuál es la url de la web?';

const String urlFormat = '''
El formato de texto es incorrecto. Se debe respetar el siguiente formato:\n
1. Prefijo - 'https://' o 'http://'\n
2. Subdominio - Ejemplo: 'www.'\n
3. Nombre del dominio - Ejemplo: 'armandocasas'\n
4. Extensión del dominio - Ejemplo: '.com', '.es', '.net'\n
5. Url adicional\n
Ejemplo: https://www.google.com/search?q=telegram\n
''';

const String askElements = 'Bien. ¿Cuál es el elemento de búsqueda?\n(Clic derecho > Inspeccionar > Clic derecho > Copiar > Copiar selector)';

const String askAttributes = 'Perfecto. ¿Cuáles son los atributos a consultar? Separa cada atributo con un espacio en blanco.\nPor ejemplo: title href style id class';

const String webErrorParams = 'Los parámetros no se han ingresado correctamente.';

String newFrecuencyTime (int minutesFrecuency) => 'Perfecto, la búsqueda se hará cada $minutesFrecuency minuto${minutesFrecuency != 1 ? 's' : ''}.';

String currentFrecuencyTime (int minutesFrecuency) => 'La búsqueda actualmente se hace cada $minutesFrecuency minuto${minutesFrecuency != 1 ? 's' : ''}.';

const String askFrecuencyTime = '¿Cuál es la nueva frecuencia en minutos?';

const String frecuencyTimeFormat = 'Debes ingresar un número válido mayor a 0.';

const String askToDelete = '¿Deseas eliminar la url de la web ingresada? La búsqueda se detendrá.';

const String yesNoFormat = 'Debes seleccionar una de las opciones. (Sí o No)';

const String deleteCompleted = 'Listo, la url se ha eliminado correctamente.';

const String deleteCanceled = 'No hay problema, la búsqueda se mantiene activa.';

const String askEmptyWeb = 'Aún no haz ingresado una web para realizar la búsqueda. ¿Deseas agregarla ahora?';

const String emptyWebCanceled = 'No hay problema, si quieres ver las opciones de inicio, escribe /start.';

const String searchEnded = 'La búsqueda ha finalizado.';

const String anotherSearch = 'Para realizar una nueva búsqueda, ingresa /web.';

String elementsFound (int length) => 'Se ha encontrado $length elemento${length != 1 ? 's' : ''}.';