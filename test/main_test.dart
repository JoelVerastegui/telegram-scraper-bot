import 'dart:async';
import 'package:test/test.dart';

import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_scraper/web_scraper.dart';

import 'package:web_scraping_telegram_bot/utils/constants.dart';

part 'mocks.dart';

void main() {
  
  group('Commands execution tests.', () {
    
    late MockMessageContext ctx;
    late MockConversations conversations;

    setUp(() {
      conversations = MockConversations();
      ctx = MockMessageContext();

      when(() => ctx.conversations).thenReturn(conversations);

      when(() => ctx.reply(any())).thenAnswer((_) async {});

      when(() => conversations.enter(any())).thenAnswer((_) async {});
    });

    test('Start command has been called.', () async {

      await sendMessage(ctx, '/start');

      verify(() => ctx.reply(
        any(that: equals(startResponse))
      )).called(1);

    });

    test('Web command has been called.', () async {

      await sendMessage(ctx, '/web');

      verify(() => conversations.enter(
        any(that: equals(webConversationName))
      )).called(1);
      
    });

    test('Time command has been called.', () async {

      await sendMessage(ctx, '/time');

      verify(() => conversations.enter(
        any(that: equals(timeConversationName))
      )).called(1);

    });

    test('Delete command has been called.', () async {

      await sendMessage(ctx, '/delete');

      verify(() => conversations.enter(
        any(that: equals(deleteConversationName))
      )).called(1);

    });

    test('Unknown command has been called.', () async {

      await sendMessage(ctx, '/random');

      verify(() => ctx.reply(
        any(that: equals(errorResponse))
      )).called(1);

    });
    
  });
  
  group('Buttons execution tests.', () {
    
    late MockMessageContext ctx;
    late MockConversations conversations;

    setUp(() {
      conversations = MockConversations();
      ctx = MockMessageContext();

      when(() => ctx.conversations).thenReturn(conversations);

      when(() => conversations.enter(any())).thenAnswer((_) async {});
    });

    test('Web button has been pressed.', () async {

      await sendMessage(ctx, webButtonText);

      verify(() => conversations.enter(
        any(that: equals(webConversationName))
      )).called(1);

    });

    test('Time button has been pressed.', () async {

      await sendMessage(ctx, timeButtonText);

      verify(() => conversations.enter(
        any(that: equals(timeConversationName))
      )).called(1);

    });

    test('Delete button has been pressed.', () async {

      await sendMessage(ctx, deleteButtonText);

      verify(() => conversations.enter(
        any(that: equals(deleteConversationName))
      )).called(1);

    });

  });

  group('Web conversation tests.', () {
    
    late MockMessageContext ctx;

    setUp(() {
      ctx = MockMessageContext();

      when(() => ctx.reply(any())).thenAnswer((_) async {});
    });

    test('Step 1 tests.', () async {
      
      when(() => ctx.messageText).thenReturn('Random text');

      await webConversationStep1(ctx);

      verify(() => ctx.reply(
        any(that: equals(askUrl))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(urlFormat))
      )).called(1);

      when(() => ctx.messageText).thenReturn('https://www.google.com');

      await webConversationStep1(ctx);

      verify(() => ctx.reply(
        any(that: equals(askUrl))
      )).called(1);

      verifyNever(() => ctx.reply(
        any(that: equals(urlFormat))
      ));

    });

    test('Step 2 tests.', () async {

      when(() => ctx.messageText).thenReturn('   ');

      await webConversationStep2(ctx);

      verifyNever(() => ctx.reply(
        any(that: equals(askElements))
      ));

      when(() => ctx.messageText).thenReturn('div > a');

      await webConversationStep2(ctx);

      verify(() => ctx.reply(
        any(that: equals(askElements))
      )).called(1);

    });

    test('Step 3 tests.', () async {
      
      when(() => ctx.messageText).thenReturn('   ');

      await webConversationStep3(ctx);

      verifyNever(() => ctx.reply(
        any(that: equals(askAttributes))
      ));

      when(() => ctx.messageText).thenReturn('href class id');

      await webConversationStep3(ctx);

      verify(() => ctx.reply(
        any(that: equals(askAttributes))
      )).called(1);

    });

    test('Time message display tests.', () async {
      
      when(() => ctx.messageText).thenReturn('1');

      await webConversationTimeDisplay(ctx);

      verify(() => ctx.reply(
        any(that: equals(newFrecuencyTime(1)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(backToStart))
      )).called(1);

      when(() => ctx.messageText).thenReturn('5');

      await webConversationTimeDisplay(ctx);

      verify(() => ctx.reply(
        any(that: equals(newFrecuencyTime(5)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(backToStart))
      )).called(1);

      when(() => ctx.messageText).thenReturn('300');

      await webConversationTimeDisplay(ctx);

      verify(() => ctx.reply(
        any(that: equals(newFrecuencyTime(300)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(backToStart))
      )).called(1);

    });

  });

  group('Time conversation tests.', () {
    
    late MockMessageContext ctx;

    setUp(() {
      ctx = MockMessageContext();

      when(() => ctx.reply(any())).thenAnswer((_) async {});
    });

    test('Time param is greater than 0.', () async {
      
      when(() => ctx.messageText).thenReturn('1');

      await timeConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(currentFrecuencyTime(5)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(askFrecuencyTime))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(newFrecuencyTime(1)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(backToStart))
      )).called(1);
      
      when(() => ctx.messageText).thenReturn('7');

      await timeConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(currentFrecuencyTime(5)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(askFrecuencyTime))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(newFrecuencyTime(7)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(backToStart))
      )).called(1);

    });

    test('Time param has an invalid format.', () async {
      
      when(() => ctx.messageText).thenReturn('0');

      await timeConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(currentFrecuencyTime(5)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(askFrecuencyTime))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(frecuencyTimeFormat))
      )).called(1);

      when(() => ctx.messageText).thenReturn('Random text');

      await timeConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(currentFrecuencyTime(5)))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(askFrecuencyTime))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(frecuencyTimeFormat))
      )).called(1);

    });

  });

  group('Delete conversation tests.', () {
    
    late MockMessageContext ctx;

    setUp(() {
      ctx = MockMessageContext();

      when(() => ctx.reply(any())).thenAnswer((_) async {});
    });

    test('Yes option selected to delete.', () async {
      
      when(() => ctx.messageText).thenReturn('Sí');

      await deleteConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(askToDelete))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(deleteCompleted))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(backToStart))
      )).called(1);

    });

    test('No option selected to delete.', () async {
      
      when(() => ctx.messageText).thenReturn('No');

      await deleteConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(askToDelete))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(deleteCanceled))
      )).called(1);

    });

    test('Invalid option selected to delete.', () async {
      
      when(() => ctx.messageText).thenReturn('Random text');

      await deleteConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(askToDelete))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(yesNoFormat))
      )).called(1);

    });

  });

  group('Empty conversation tests.', () {
    
    late MockMessageContext ctx;

    setUp(() {
      ctx = MockMessageContext();

      when(() => ctx.reply(any())).thenAnswer((_) async {});
    });

    test('Yes option selected to empty.', () async {
      
      when(() => ctx.messageText).thenReturn('Sí');

      await emptyConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(askEmptyWeb))
      )).called(1);

      verifyNever(() => ctx.reply(
        any()
      ));

    });

    test('No option selected to empty.', () async {
      
      when(() => ctx.messageText).thenReturn('No');

      await emptyConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(askEmptyWeb))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(emptyWebCanceled))
      )).called(1);

    });

    test('Invalid option selected to empty.', () async {
      
      when(() => ctx.messageText).thenReturn('Random text');

      await emptyConversation(ctx);

      verify(() => ctx.reply(
        any(that: equals(askEmptyWeb))
      )).called(1);

      verify(() => ctx.reply(
        any(that: equals(yesNoFormat))
      )).called(1);

    });

  });

  group('Timer tests.', () {
    
    late MockMessageContext ctx;
    late MockTimerCallback timerCb;
    late TimerMimic timerMimic;

    setUp(() {
      ctx = MockMessageContext();
      timerCb = MockTimerCallback();
      timerMimic = TimerMimic(ctx, timerCb.onTick);

      when(() => ctx.reply(any())).thenAnswer((_) async {});

      registerFallbackValue(0);
    });

    tearDown(() {
      timerMimic.stopTimer();
      reset(timerCb);
    });

    test('Timer functionality tests.', () {
      
      fakeAsync((async) {

        timerMimic.startTimer();

        async.elapse(const Duration(seconds: 4));

        verifyNever(() => timerCb.onTick(any()));

        async.elapse(const Duration(seconds: 1));

        verify(() => timerCb.onTick(1)).called(1);

        verifyNever(() => timerCb.onTick(2));

        async.elapse(const Duration(seconds: 5));

        verify(() => timerCb.onTick(2)).called(1);

      });

    });

    test('Search found tests.', () {
      
      fakeAsync((async) {

        timerMimic.startTimer();

        async.elapse(const Duration(seconds: 4));

        verifyNever(() => timerCb.onTick(any()));

        async.elapse(const Duration(seconds: 1));

        verify(() => timerCb.onTick(1)).called(1);

        async.elapse(const Duration(seconds: 5));

        verify(() => timerCb.onTick(2)).called(1);

        async.elapse(const Duration(seconds: 5));

        verify(() => timerCb.onTick(3)).called(1);

        verify(() => ctx.reply(
          any(that: equals(searchEnded))
        )).called(1);

        verify(() => ctx.reply(
          any(that: equals(anotherSearch))
        )).called(1);

      });

    });

  });

  group('Web search elements tests.', () {
    
    late MockMessageContext ctx;

    setUp(() {
      ctx = MockMessageContext();

      when(() => ctx.reply(any())).thenAnswer((_) async {});
    });

    test('Elements found tests.', () async {
      
      await webSearchTesting(ctx, '#lista > .item');

      verify(() => ctx.reply(
        any(that: equals(elementsFound(2)))
      )).called(1);

      await webSearchTesting(ctx, '#form > input[name="nombre"]');

      verify(() => ctx.reply(
        any(that: equals(elementsFound(1)))
      )).called(1);

      await webSearchTesting(ctx, '.items li[data-value="b"]');

      verify(() => ctx.reply(
        any(that: equals(elementsFound(1)))
      )).called(1);

    });

    test('Elements not found tests.', () async {
      
      await webSearchTesting(ctx, '#lista > #item-3');

      verifyNever(() => ctx.reply(any()));

      await webSearchTesting(ctx, '#form > .btn');

      verifyNever(() => ctx.reply(any()));

      await webSearchTesting(ctx, 'h1[class="titulo-random"]');

      verifyNever(() => ctx.reply(any()));

    });

  });

}
