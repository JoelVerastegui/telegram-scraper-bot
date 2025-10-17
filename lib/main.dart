import 'dart:async' show Timer;
import 'dart:io' show Platform, exit;

import 'package:televerse/plugins/conversation.dart';
import 'package:televerse/televerse.dart';
import 'package:web_scraper/web_scraper.dart';

late Bot bot;
final webScraper = WebScraper();
String inputUrl = '';
String searchElement = '';
String searchAttributes = '';
int minutesFrecuency = 5;
Timer? timer; 

void main () async {
  String telegramToken = String.fromEnvironment('TELEGRAM_BOT_TOKEN', defaultValue: Platform.environment['TELEGRAM_BOT_TOKEN'] ?? '');

  if (telegramToken.isEmpty) {
    print('No se ha cargado el token correctamente.');

    exit(0);
  }

  telegramBot(telegramToken);
}

Future<void> telegramBot(String token) async {
  bot = Bot<Context>(token);

  bot.plugin(ConversationPlugin<Context>());

  bot.use(createConversation<Context>('newEditScraping', newEditScraping));
  bot.use(createConversation<Context>('editFrecuency', editFrecuency));
  bot.use(createConversation<Context>('deleteScraping', deleteScraping));
  bot.use(createConversation<Context>('emptyScraping', emptyScraping));

  final menu = KeyboardMenu();

  menu.text('Crear/Editar Web Scraping', (ctx) async {
    await ctx.conversation.enter('newEditScraping');
  }).row();

  menu.text('Cambiar frecuencia de notificaciones', (ctx) async {
    await ctx.conversation.enter('editFrecuency');
  }).row();

  menu.text('Eliminar Web Scraping', (ctx) async {
    await ctx.conversation.enter('deleteScraping');
  });

  menu.oneTime().resized();

  bot.attachMenu(menu);

  bot.command('start', (ctx) async {
    await ctx.reply(
      "Hola, ¿qué acción deseas realizar hoy? Si necesitas más información, escribe /help.",
      replyMarkup: menu,
    );
  });

  bot.command('web', (ctx) async {
    await ctx.conversation.enter('newEditScraping');
  });

  bot.command('time', (ctx) async {
    await ctx.conversation.enter('editFrecuency');
  });

  bot.command('delete', (ctx) async {
    await ctx.conversation.enter('deleteScraping');
  });

  bot.command('help', (ctx) async {
    final commands = 
'''
/start: Muestra las opciones de inicio.\n
/web: Crea o edita la web ingresada.\n
/time: Modifica la frecuencia en minutos en que se realiza la búsqueda.\n
/delete: Elimina la web ingresada.\n
/help: Muestra los comandos disponibles.
''';

    await ctx.reply(commands);
  });
  
  bot.onError((error) async {
    print('Bot Error: ${error.error}');
    if (error.hasContext) {
      await error.ctx!.reply('Lo siento, algo ha salido mal.');
    }
  });
  
  await bot.start();
}

Future<void> newEditScraping (Conversation<Context> conversation, Context ctx) async {
  try {
    final regex = RegExp(r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)');

    await ctx.reply("¿Cuál es la url de la web?");

    final urlCtx = await conversation.waitUntil(
      (ctx) => regex.hasMatch(ctx.text ?? ''),
      timeout: Duration(minutes: 2),
      otherwise: (ctx) async {
        final urlFormat = 
'''
El formato de texto es incorrecto. Se debe respetar el siguiente formato:\n
1. Prefijo - 'https://' o 'http://'\n
2. Subdominio - Ejemplo: 'www.'\n
3. Nombre del dominio - Ejemplo: 'armandocasas'\n
4. Extensión del dominio - Ejemplo: '.com', '.es', '.net'\n
5. Url adicional\n
Ejemplo: https://www.google.com/search?q=telegram\n
''';
        await ctx.reply(urlFormat);
      },
    );

    await urlCtx.reply("Bien. ¿Cuál es el elemento de búsqueda?\n(Clic derecho > Inspeccionar > Clic derecho > Copiar > Copiar selector)");

    final elementCtx = await conversation.waitFor(
      bot.filters.text.matches,
      timeout: Duration(minutes: 2),
    );

    await urlCtx.reply("Perfecto. ¿Cuáles son los atributos a consultar? Separa cada atributo con un espacio en blanco.\nPor ejemplo: title href style id class");

    final attrCtx = await conversation.waitUntil(
      bot.filters.text.matches,
      timeout: Duration(minutes: 2),
    );

    if (urlCtx.text != null && elementCtx.text != null && attrCtx.text != null) {
      inputUrl = urlCtx.text!;
      searchElement = elementCtx.text!;
      searchAttributes = attrCtx.text!;

      startTimer(ctx);

      await elementCtx.reply("Perfecto, la búsqueda se hará cada $minutesFrecuency minuto${minutesFrecuency != 1 ? 's' : ''}.");

      await ctx.reply("Para volver a ver las opciones de inicio, ingresa /start.");
    } else {
      await ctx.reply("Los parámetros no se han ingresado correctamente.");
    }
  } on ConversationTimeoutException {
    await ctx.reply("Lo siento, el tiempo de espera se ha agotado.");
  }
}

Future<void> editFrecuency (Conversation<Context> conversation, Context ctx) async {
  try {
    await ctx.reply("La búsqueda actualmente se hace cada $minutesFrecuency minuto${minutesFrecuency != 1 ? 's' : ''}.");
    await ctx.reply("¿Cuál es la nueva frecuencia en minutos?");

    final minutesCtx = await conversation.waitUntil(
      (ctx) => int.tryParse(ctx.text ?? '') != null && int.parse(ctx.text!) > 0,
      timeout: Duration(minutes: 2),
      otherwise: (ctx) async {
        await ctx.reply("Debes ingresar un número válido mayor a 0.");
      },
    );

    await minutesCtx.reply("Perfecto, la búsqueda se hará cada ${minutesCtx.text} minuto${minutesCtx.text != '1' ? 's' : ''}.");

    minutesFrecuency = int.parse(minutesCtx.text!);

    if (inputUrl.isEmpty || searchElement.isEmpty || searchAttributes.isEmpty) {
      await ctx.conversation.enter('emptyScraping');
    } else {
      await ctx.reply("Para volver a ver las opciones de inicio, ingresa /start.");

      startTimer(ctx);
    }
  } on ConversationTimeoutException {
    await ctx.reply("Lo siento, el tiempo de espera se ha agotado.");
  }
}

Future<void> deleteScraping (Conversation<Context> conversation, Context ctx) async {
  try {
    if (inputUrl.isEmpty || searchElement.isEmpty || searchAttributes.isEmpty) {
      return await ctx.conversation.enter('emptyScraping');
    }

    final menu = KeyboardMenu()
      .text('Sí', (_) {})
      .text('No', (_) {})
      .oneTime()
      .resized();

    await ctx.reply("¿Deseas eliminar la url de la web ingresada? La búsqueda se detendrá.", replyMarkup: menu);

    final yesNoCtx = await conversation.waitUntil(
      (ctx) => ctx.text == 'Sí' || ctx.text == 'No',
      timeout: Duration(minutes: 2),
      otherwise: (ctx) async {
        await ctx.reply("Debe seleccionar una de las opciones. (Sí o No)");
      },
    );

    if (yesNoCtx.text! == 'Sí') {
      timer?.cancel();

      inputUrl = '';
      searchElement = '';
      searchAttributes = '';

      await ctx.reply("Listo, la url se ha eliminado correctamente.");

      await ctx.reply("Para volver a ver las opciones de inicio, ingresa /start.");
    } else {
      await ctx.reply("No hay problema, la búsqueda se mantiene activa.");
    }
  } on ConversationTimeoutException {
    await ctx.reply("Lo siento, el tiempo de espera se ha agotado.");
  }
}

Future<void> emptyScraping (Conversation<Context> conversation, Context ctx) async {
  try {
    final menu = KeyboardMenu()
      .text('Sí', (_) {})
      .text('No', (_) {})
      .oneTime()
      .resized();

    await ctx.reply("Aún no haz ingresado una web para realizar la búsqueda. ¿Deseas agregarla ahora?", replyMarkup: menu);

    final yesNoCtx = await conversation.waitUntil(
      (ctx) => ctx.text == 'Sí' || ctx.text == 'No',
      timeout: Duration(minutes: 2),
      otherwise: (ctx) async {
        await ctx.reply("Debes seleccionar una de las opciones. (Sí o No)");
      },
    );

    if (yesNoCtx.text! == 'Sí') {
      await ctx.conversation.enter('newEditScraping');
    } else {
      await ctx.reply("No hay problema, si quieres ver las opciones de inicio, escribe /start.");
    }
  } on ConversationTimeoutException {
    await ctx.reply("Lo siento, el tiempo de espera se ha agotado.");
  }
}

Future<void> startTimer(Context ctx) async {
  timer?.cancel();

  timer = Timer.periodic(Duration(minutes: minutesFrecuency), (timer) async {
    final elementsFound = await webSearch(ctx);

    if (elementsFound) {
      inputUrl = '';
      searchElement = '';
      searchAttributes = '';

      await ctx.reply("La búsqueda ha finalizado.");
      await ctx.reply("Para realizar una nueva búsqueda, ingresa /web.");
      
      timer.cancel();
    }
  });
}

Future<bool> webSearch(Context ctx) async {
  await webScraper.loadFullURL(inputUrl);

  final attributes = searchAttributes.split(' ');

  final results = webScraper.getElement(searchElement, attributes);

  if (results.isNotEmpty) {
    await ctx.reply('Se ha encontrado ${results.length} elemento${results.length != 1 ? 's' : ''}.');

    for(final result in results) {
      String response = '';

      for(final attr in attributes) {
        if (attr == 'href') {
          final baseUrl = inputUrl.substring(0, inputUrl.indexOf('/', 8));

          if (result['attributes'][attr].toString().isNotEmpty && !result['attributes'][attr].toString().contains(baseUrl)) {
            response += '$attr: ${baseUrl + result['attributes'][attr].toString().replaceAll(' ', '%20')}\n';
            continue;
          }

          response += '$attr: ${result['attributes'][attr].toString().replaceAll(' ', '%20')}\n';
          continue;
        }

        response += '$attr: ${result['attributes'][attr]}\n';
      }

      await ctx.reply(response);
    }

    return true;
  } else {
    return false;
  }
}