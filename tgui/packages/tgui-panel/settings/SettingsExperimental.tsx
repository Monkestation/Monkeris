import { useDispatch, useSelector } from 'tgui/backend';
import { LabeledList, Section, Slider, Stack } from 'tgui-core/components';
import { toFixed } from 'tgui-core/math';

import { updateSettings } from './actions';
import { selectSettings } from './selectors';

export function ExperimentalSettings(props) {
  const { scrollTrackingTolerance } = useSelector(selectSettings);
  const dispatch = useDispatch();

  return (
    <Section>
      <Stack vertical>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item
              label="ScrollTT"
              tooltip="Scroll Tracking Tolerance: The smallest possible scroll offset that is still trackable"
            >
              <Slider
                width="100%"
                step={1}
                stepPixelSize={2}
                minValue={12}
                maxValue={64}
                value={scrollTrackingTolerance}
                format={(value) => toFixed(value)}
                onDrag={(e, value) =>
                  dispatch(
                    updateSettings({
                      scrollTrackingTolerance: value,
                    }),
                  )
                }
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
    </Section>
  );
}
