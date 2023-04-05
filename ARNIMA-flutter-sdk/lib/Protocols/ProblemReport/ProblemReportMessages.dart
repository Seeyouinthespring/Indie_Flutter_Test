import 'package:AriesFlutterMobileAgent/Utils/MessageType.dart';
import 'package:uuid/uuid.dart';

Object createProblemReportMessage(String comment, String threadId) {
  return {
    '@type': MessageType.ProblemReport,
    '@id': Uuid().v4(),
    '~thread': {
      'thid': threadId,
    },
    'noticed_time': new DateTime.now().toString(),
    'comment': comment,
    'impact': 'thread',
    'problem_items': [
      {
        '~thread': {
          'thid': threadId,
        },
      },
    ],
  };
}

