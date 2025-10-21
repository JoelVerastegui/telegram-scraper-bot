part of 'main_test.dart';

abstract class Conversations {
  Future<void> enter(String conversationName);
}

abstract class MessageContext {
  String get messageText;
  Future<void> reply(String text);
  Conversations get conversations;
}

class TimerMimic {
  Timer? timer;
  int searchCounter = 0;
  final Function(int) onTick;
  MessageContext ctx;

  TimerMimic(this.ctx, this.onTick);

  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      searchCounter++;

      onTick(searchCounter);

      if (searchCounter >= 3) {
        await ctx.reply(searchEnded);

        await ctx.reply(anotherSearch);

        timer?.cancel();
      }
    });
  }

  void stopTimer() => timer?.cancel();
}

class MockTimerCallback extends Mock {
  void onTick(int tick);
}

class MockMessageContext extends Mock implements MessageContext {}

class MockConversations extends Mock implements Conversations {}

//* Commands and buttons methods

Future<void> sendMessage(MessageContext ctx, String message) async {
  if (message.startsWith('/')) {
    switch (message) {
      case '/start': startCommand(ctx); break;
      case '/web': webCommand(ctx); break;
      case '/time': timeCommand(ctx); break;
      case '/delete': deleteCommand(ctx); break;
      case '/help': helpCommand(ctx); break;
      default: onError(ctx); break;
    }
  } else {
    switch (message) {
      case webButtonText: webCommand(ctx); break;
      case timeButtonText: timeCommand(ctx); break;
      case deleteButtonText: deleteCommand(ctx); break;
      default: break;
    }
  }
}

Future<void> startCommand(MessageContext ctx) async {
  await ctx.reply(startResponse);
}

Future<void> webCommand(MessageContext ctx) async {
  await ctx.conversations.enter(webConversationName);
}

Future<void> timeCommand(MessageContext ctx) async {
  await ctx.conversations.enter(timeConversationName);
}

Future<void> deleteCommand(MessageContext ctx) async {
  await ctx.conversations.enter(deleteConversationName);
}

Future<void> helpCommand(MessageContext ctx) async {
  await ctx.reply(helpResponse);
}

Future<void> onError(MessageContext ctx) async {
  await ctx.reply(errorResponse);
}

//* Web conversation methods

Future<void> webConversationStep1(MessageContext ctx) async {
  await ctx.reply(askUrl);

  final text = ctx.messageText.trim();

  final regex = RegExp(urlRegex);

  if (!regex.hasMatch(text)) {
    await ctx.reply(urlFormat);
  }
}

Future<void> webConversationStep2(MessageContext ctx) async {
  if (ctx.messageText.trim().isNotEmpty) {
    await ctx.reply(askElements);
  }
}

Future<void> webConversationStep3(MessageContext ctx) async {
  if (ctx.messageText.trim().isNotEmpty) {
    await ctx.reply(askAttributes);
  }
}

Future<void> webConversationTimeDisplay(MessageContext ctx) async {
  if (ctx.messageText.trim().isNotEmpty) {
    await ctx.reply(newFrecuencyTime(int.parse(ctx.messageText)));

    await ctx.reply(backToStart);
  }
}

//* Time conversation methods

Future<void> timeConversation(MessageContext ctx) async {
  await ctx.reply(currentFrecuencyTime(5));

  await ctx.reply(askFrecuencyTime);

  final int? minutesFrecuency = int.tryParse(ctx.messageText);

  if (minutesFrecuency != null && minutesFrecuency > 0) {
    await ctx.reply(newFrecuencyTime(minutesFrecuency));

    await ctx.reply(backToStart);
  } else {
    await ctx.reply(frecuencyTimeFormat);
  }
}

//* Delete conversation methods

Future<void> deleteConversation(MessageContext ctx) async {
  await ctx.reply(askToDelete);

  final yesNoAnswer = ctx.messageText.trim();

  if (yesNoAnswer == 'Sí' || yesNoAnswer == 'No') {
    if (yesNoAnswer == 'Sí') {
      await ctx.reply(deleteCompleted);

      await ctx.reply(backToStart);
    } else {
      await ctx.reply(deleteCanceled);
    }
  } else {
    await ctx.reply(yesNoFormat);
  }
}

//* Empty conversation methods

Future<void> emptyConversation(MessageContext ctx) async {
  await ctx.reply(askEmptyWeb);

  final yesNoAnswer = ctx.messageText.trim();

  if (yesNoAnswer == 'Sí' || yesNoAnswer == 'No') {
    if (yesNoAnswer == 'No') {
      await ctx.reply(emptyWebCanceled);
    }
  } else {
    await ctx.reply(yesNoFormat);
  }
}

//* Web search methods

Future<void> webSearchTesting(MessageContext ctx, String elements) async {
  final htmlTemplate = '''
<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8">
    <title>Ejemplo mínimo</title>
  </head>
  <body>
    <h1 id="titulo-principal" class="titulo">Hola Mundo</h1>
    <p id="parrafo-1" class="texto" data-role="intro">Párrafo corto de ejemplo.</p>

    <ul id="lista" class="items">
      <li class="item" id="item-1" data-value="a">Elemento A</li>
      <li class="item" id="item-2" data-value="b">Elemento B</li>
    </ul>

    <a id="enlace" class="link" href="https://example.com" target="_blank">Visitar ejemplo</a>

    <img id="logo" class="imagen" src="logo.png" alt="Logo de prueba" data-size="small">

    <form id="form" class="formulario" action="/send" method="post">
      <input id="nombre" class="input" name="nombre" type="text" value="Usuario">
      <button id="btn" class="boton" type="submit">Enviar</button>
    </form>
  </body>
</html>
''';

  final webScraper = WebScraper();
  
  webScraper.loadFromString(htmlTemplate);

  final results = webScraper.getElement(elements, []);

  if (results.isNotEmpty) {
    await ctx.reply(elementsFound(results.length));
  }
}