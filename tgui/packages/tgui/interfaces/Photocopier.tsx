import {
  Box,
  Button,
  Flex,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface PhotocopierData {
  hasCopyitem: BooleanLike;
  toner: number;
  copies: number;
  isSilicon: BooleanLike;
  max_copies: number;
}

export const Photocopier = () => {
  const { act, data } = useBackend<PhotocopierData>();
  const { hasCopyitem, toner, copies, max_copies, isSilicon } = data;

  const has_enough_toner = !(toner <= 0);

  return (
    <Window width={400} height={350} title="Photocopier">
      <Window.Content>
        {hasCopyitem ? (
          <Stack.Item>
            <Button onClick={() => act('remove')} mb={2}>
              Remove Item
            </Button>

            <Flex align="center" mb={2}>
              <Flex.Item>
                <NumberInput
                  animated
                  width={2.6}
                  height={1.65}
                  step={1}
                  stepPixelSize={8}
                  minValue={1}
                  maxValue={max_copies}
                  value={copies}
                  onDrag={(value: number) =>
                    act('set_copies', {
                      num_copies: value,
                    })
                  }
                />
              </Flex.Item>
              <Flex.Item>
                <Button
                  ml={0.2}
                  icon="copy"
                  textAlign="center"
                  disabled={!has_enough_toner}
                  onClick={() => act('copy')}
                >
                  Copy
                </Button>
              </Flex.Item>
            </Flex>
          </Stack.Item>
        ) : (
          toner > 0 && (
            <Section title="Options">
              <Box color="average">No inserted item.</Box>
            </Section>
          )
        )}
        <Section title="Toner">
          <Stack>
            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Current toner level">
                  <Box color={toner > 0 ? 'default' : 'red'}>{toner}</Box>
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            {toner === 0 && (
              <Stack.Item>
                <NoticeBox color="red" mt={1}>
                  Please insert a new toner cartridge!
                </NoticeBox>
              </Stack.Item>
            )}
          </Stack>
        </Section>
        {!!isSilicon && <AIOptions />}
      </Window.Content>
    </Window>
  );
};

// const Toner = (props) => {
//   const { act, data } = useBackend();
//   const { has_toner, max_toner, current_toner } = data;

//   const average_toner = max_toner * 0.66;
//   const bad_toner = max_toner * 0.33;

//   return (
//     <Section
//       title="Toner"
//       buttons={
//         <Button
//           disabled={!has_toner}
//           onClick={() => act('remove_toner')}
//           icon="eject"
//         >
//           Eject
//         </Button>
//       }
//     >
//       <ProgressBar
//         ranges={{
//           good: [average_toner, max_toner],
//           average: [bad_toner, average_toner],
//           bad: [0, bad_toner],
//         }}
//         value={current_toner}
//         minValue={0}
//         maxValue={max_toner}
//       />
//     </Section>
//   );
// };

const AIOptions = (props) => {
  const { act, data } = useBackend<PhotocopierData>();
  const { isSilicon } = data;

  return (
    <Section title="AI Options">
      <Box>
        <Button
          fluid
          icon="images"
          textAlign="center"
          disabled={!isSilicon}
          onClick={() => act('aipic')}
        >
          Print photo from database
        </Button>
      </Box>
    </Section>
  );
};
