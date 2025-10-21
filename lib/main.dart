import 'dart:async' show Timer;
import 'dart:io' show Platform, exit;

import 'package:televerse/plugins/conversation.dart';
import 'package:televerse/televerse.dart';
import 'package:web_scraper/web_scraper.dart';

import 'package:web_scraping_telegram_bot/utils/constants.dart';

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

  bot.use(createConversation<Context>(webConversationName, newEditScraping));
  bot.use(createConversation<Context>(timeConversationName, editFrecuency));
  bot.use(createConversation<Context>(deleteConversationName, deleteScraping));
  bot.use(createConversation<Context>(emptyConversationName, emptyScraping));

  final menu = KeyboardMenu();

  menu.text(webButtonText, (ctx) async {
    await ctx.conversation.enter(webConversationName);
  }).row();

  menu.text(timeButtonText, (ctx) async {
    await ctx.conversation.enter(timeConversationName);
  }).row();

  menu.text(deleteButtonText, (ctx) async {
    await ctx.conversation.enter(deleteConversationName);
  });

  menu.oneTime().resized();

  bot.attachMenu(menu);

  bot.command('start', (ctx) async {
    await ctx.reply(
      startResponse,
      replyMarkup: menu,
    );
  });

  bot.command('web', (ctx) async {
    await ctx.conversation.enter(webConversationName);
  });

  bot.command('time', (ctx) async {
    await ctx.conversation.enter(timeConversationName);
  });

  bot.command('delete', (ctx) async {
    await ctx.conversation.enter(deleteConversationName);
  });

  bot.command('help', (ctx) async {
    final commands = helpResponse;

    await ctx.reply(commands);
  });
  
  bot.onError((error) async {
    print('Bot Error: ${error.error}');
    if (error.hasContext) {
      await error.ctx!.reply(errorResponse);
    }
  });
  
  await bot.start();
}

Future<void> newEditScraping (Conversation<Context> conversation, Context ctx) async {
  try {
    final regex = RegExp(urlRegex);

    await ctx.reply(askUrl);

    final urlCtx = await conversation.waitUntil(
      (ctx) => regex.hasMatch(ctx.text ?? ''),
      timeout: Duration(minutes: 2),
      otherwise: (ctx) async {
        await ctx.reply(urlFormat);
      },
    );

    await urlCtx.reply(askElements);

    final elementCtx = await conversation.waitFor(
      bot.filters.text.matches,
      timeout: Duration(minutes: 2),
    );

    await urlCtx.reply(askAttributes);

    final attrCtx = await conversation.waitUntil(
      bot.filters.text.matches,
      timeout: Duration(minutes: 2),
    );

    if (urlCtx.text != null && elementCtx.text != null && attrCtx.text != null) {
      inputUrl = urlCtx.text!;
      searchElement = elementCtx.text!;
      searchAttributes = attrCtx.text!;

      startTimer(ctx);

      await elementCtx.reply(newFrecuencyTime(minutesFrecuency));

      await ctx.reply(backToStart);
    } else {
      await ctx.reply(webErrorParams);
    }
  } on ConversationTimeoutException {
    await ctx.reply(timeoutException);
  }
}

Future<void> editFrecuency (Conversation<Context> conversation, Context ctx) async {
  try {
    await ctx.reply(currentFrecuencyTime(minutesFrecuency));
    await ctx.reply(askFrecuencyTime);

    final minutesCtx = await conversation.waitUntil(
      (ctx) => int.tryParse(ctx.text ?? '') != null && int.parse(ctx.text!) > 0,
      timeout: Duration(minutes: 2),
      otherwise: (ctx) async {
        await ctx.reply(frecuencyTimeFormat);
      },
    );

    await minutesCtx.reply(newFrecuencyTime(int.parse(minutesCtx.text!)));

    minutesFrecuency = int.parse(minutesCtx.text!);

    if (inputUrl.isEmpty || searchElement.isEmpty || searchAttributes.isEmpty) {
      await ctx.conversation.enter(emptyConversationName);
    } else {
      await ctx.reply(backToStart);

      startTimer(ctx);
    }
  } on ConversationTimeoutException {
    await ctx.reply(timeoutException);
  }
}

Future<void> deleteScraping (Conversation<Context> conversation, Context ctx) async {
  try {
    if (inputUrl.isEmpty || searchElement.isEmpty || searchAttributes.isEmpty) {
      return await ctx.conversation.enter(emptyConversationName);
    }

    final menu = KeyboardMenu()
      .text('Sí', (_) {})
      .text('No', (_) {})
      .oneTime()
      .resized();

    await ctx.reply(askToDelete, replyMarkup: menu);

    final yesNoCtx = await conversation.waitUntil(
      (ctx) => ctx.text == 'Sí' || ctx.text == 'No',
      timeout: Duration(minutes: 2),
      otherwise: (ctx) async {
        await ctx.reply(yesNoFormat);
      },
    );

    if (yesNoCtx.text! == 'Sí') {
      timer?.cancel();

      inputUrl = '';
      searchElement = '';
      searchAttributes = '';

      await ctx.reply(deleteCompleted);

      await ctx.reply(backToStart);
    } else {
      await ctx.reply(deleteCanceled);
    }
  } on ConversationTimeoutException {
    await ctx.reply(timeoutException);
  }
}

Future<void> emptyScraping (Conversation<Context> conversation, Context ctx) async {
  try {
    final menu = KeyboardMenu()
      .text('Sí', (_) {})
      .text('No', (_) {})
      .oneTime()
      .resized();

    await ctx.reply(askEmptyWeb, replyMarkup: menu);

    final yesNoCtx = await conversation.waitUntil(
      (ctx) => ctx.text == 'Sí' || ctx.text == 'No',
      timeout: Duration(minutes: 2),
      otherwise: (ctx) async {
        await ctx.reply(yesNoFormat);
      },
    );

    if (yesNoCtx.text! == 'Sí') {
      await ctx.conversation.enter(webConversationName);
    } else {
      await ctx.reply(emptyWebCanceled);
    }
  } on ConversationTimeoutException {
    await ctx.reply(timeoutException);
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

      await ctx.reply(searchEnded);
      await ctx.reply(anotherSearch);
      
      timer.cancel();
    }
  });
}

Future<bool> webSearch(Context ctx) async {
  await webScraper.loadFullURL(inputUrl);

  final attributes = searchAttributes.split(' ');

  final results = webScraper.getElement(searchElement, attributes);

  if (results.isNotEmpty) {
    await ctx.reply(elementsFound(results.length));

    for(final result in results) {
      String response = '';

      for(final attr in attributes) {
        if (attr == 'href') {
          final baseUrl = inputUrl.substring(0, inputUrl.indexOf('/', 8));

          if (result['attributes'][attr].toString().isNotEmpty && result['attributes'][attr].toString().startsWith('/')) {
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