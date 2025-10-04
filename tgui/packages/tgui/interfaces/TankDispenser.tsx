import { Box, Button, LabeledList, Section } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface TankDispenserData {
  name: string;
  oxygentanks: number;
  plasmatanks: number;
}

export const TankDispenser = () => {
  const { act, data } = useBackend<TankDispenserData>();
  const { name, oxygentanks, plasmatanks } = data;

  return (
    <Window width={400} height={300}>
      <Window.Content>
        <Section title={name}>
          <LabeledList>
            <LabeledList.Item label="Oxygen tanks">
              <Box inline mr={2}>
                {oxygentanks}
              </Box>
              {oxygentanks > 0 ? (
                <Button content="Dispense" onClick={() => act('oxygen')} />
              ) : (
                <Box color="red" inline>
                  empty
                </Box>
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Plasma tanks">
              <Box inline mr={2}>
                {plasmatanks}
              </Box>
              {plasmatanks > 0 ? (
                <Button content="Dispense" onClick={() => act('plasma')} />
              ) : (
                <Box color="red" inline>
                  empty
                </Box>
              )}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
