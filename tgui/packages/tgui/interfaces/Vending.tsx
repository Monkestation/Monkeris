import { useState } from 'react';

import { useBackend } from 'tgui/backend';
import {
  BlockQuote,
  Box,
  Button,
  Icon,
  Input,
  LabeledList,
  Modal,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { capitalize } from 'tgui-core/string';

import { GameIcon } from '../components/GameIcon';
import { Window } from '../layouts';

interface OwnerData {
  name: string;
  dept: string;
}

interface ErrorData {
  message: string;
  isError: boolean;
}

interface VendingProductData extends ErrorData {
  name: string;
  desc: string;
  price: number;
}

interface ProductData {
  key: number;
  name: string;
  icon: string;
  price: number;
  color?: null;
  amount: number;
}

interface VendingData {
  name: string;
  panel: boolean;
  isCustom: string;
  ownerData?: OwnerData;
  isManaging: boolean;
  managingData: ErrorData;
  isVending: boolean;
  vendingData: VendingProductData;
  products?: ProductData[];
  markup?: number;
  speaker?: string;
  advertisement?: string;
  needsPin: boolean;
  pinMode: string;
}

const managing = (managingData: ErrorData) => {
  const { act } = useBackend<VendingData>();

  return (
    <>
      <Stack.Item>
        {managingData.message.length > 0 && (
          <NoticeBox
            style={{
              overflow: 'hidden',
              wordBreak: 'break-all',
            }}
          >
            {managingData.message}
          </NoticeBox>
        )}
      </Stack.Item>
      <Stack.Item>
        <Stack justify="space-between" textAlign="center">
          <Stack.Item grow>
            <Button
              fluid
              ellipsis
              icon="building"
              onClick={() => act('setdepartment')}
            >
              Organization
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              ellipsis
              icon="id-card"
              onClick={() => act('setaccount')}
            >
              Account
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button fluid ellipsis icon="tags" onClick={() => act('markup')}>
              Markup
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </>
  );
};

const custom = (props: any) => {
  const { act, data } = useBackend<VendingData>();
  const { ownerData } = data;

  return (
    <Section title={data.isManaging ? 'Managment' : 'Commercial Info'}>
      <Stack fill vertical>
        <Stack>
          <Stack.Item align="center">
            <Icon name="toolbox" size={3} mx={1} />
          </Stack.Item>
          <Stack.Item>
            <LabeledList>
              <LabeledList.Item label="Owner">
                {ownerData?.name || 'Unknown'}
              </LabeledList.Item>
              <LabeledList.Item label="Department">
                {ownerData?.dept || 'Not Specified'}
              </LabeledList.Item>
              <LabeledList.Item label="Murkup">
                {(data?.markup && data?.markup > 0 && (
                  <Box>{data.markup}</Box>
                )) ||
                  'None'}
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
        </Stack>
        {(data.isManaging && managing(data.managingData)) || null}
      </Stack>
    </Section>
  );
};

const product = (product: ProductData) => {
  const { act, data } = useBackend<VendingData>();

  return (
    <Stack.Item>
      <Stack fill height="5.9ch">
        <Stack.Item grow>
          <Button
            fluid
            height="100%"
            verticalAlignContent="middle"
            content={
              <Stack fill align="center">
                <Stack.Item
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <GameIcon
                    html={product.icon}
                    className="Vending--game-icon"
                  />
                </Stack.Item>
                <Stack.Item grow={4} textAlign="left" className="Vending--text">
                  {product.name}
                </Stack.Item>
                <Stack.Item grow textAlign="right" className="Vending--text">
                  {product.amount}
                  <Icon name="box" pl="0.6em" />
                </Stack.Item>
                {(product.price > 0 && (
                  <Stack.Item grow textAlign="right" className="Vending--text">
                    {product.price}
                    <Icon name="money-bill" pl="0.6em" />
                  </Stack.Item>
                )) ||
                  null}
              </Stack>
            }
            onClick={() => act('vend', { key: product.key })}
          />
        </Stack.Item>
        {(data.isManaging && (
          <>
            <Stack.Item grow>
              <Button
                icon="tag"
                color="yellow"
                className="Vending--icon"
                verticalAlignContent="middle"
                onClick={() => act('setprice', { key: product.key })}
              >
                Change Price
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="eject"
                color="red"
                className="Vending--icon"
                verticalAlignContent="middle"
                onClick={() => act('remove', { key: product.key })}
              >
                Remove
              </Button>
            </Stack.Item>
          </>
        )) ||
          null}
      </Stack>
    </Stack.Item>
  );
};

const pay = (vendingProduct: VendingProductData) => {
  const { act } = useBackend<VendingData>();

  return (
    <Modal className="Vending--modal">
      <Stack fill vertical justify="space-between">
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Name">
              {capitalize(vendingProduct.name)}
            </LabeledList.Item>
            <LabeledList.Item label="Description">
              {vendingProduct.desc}
            </LabeledList.Item>
            <LabeledList.Item label="Price">
              {vendingProduct.price}
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item>
          <NoticeBox color={vendingProduct.isError ? 'red' : ''}>
            {vendingProduct.message}
          </NoticeBox>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            icon="ban"
            color="red"
            content="Cancel"
            className="Vending--cancel"
            verticalAlignContent="middle"
            onClick={() => act('cancelpurchase')}
          />
        </Stack.Item>
      </Stack>
    </Modal>
  );
};

const pinModal = () => {
  const { act, data } = useBackend<VendingData>();
  const [pin, setPin] = useState('');

  const submit = () => {
    if (!pin) return;
    act('submit_pin', { pin });
    setPin('');
  };

  return (
    <Modal>
      <Stack vertical minWidth="200px">
        <Stack.Item>
          <Box bold fontSize="1.1em" mb={1}>
            {data.pinMode === 'manage' ? 'Authorization Required' : 'PIN Required'}
          </Box>
          <Box color="label" fontSize="0.9em" mb={1}>
            Enter the PIN for this account to continue.
          </Box>
          <Input
            autoFocus
            fluid
            placeholder="Enter PIN"
            value={pin}
            onChange={(val) => setPin(val)}
            onEnter={submit}
          />
        </Stack.Item>
        <Stack.Item mt={1}>
          <Stack>
            <Stack.Item grow>
              <Button fluid icon="check" disabled={!pin} onClick={submit}>
                Confirm
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                icon="ban"
                color="red"
                onClick={() => act('cancelpurchase')}
              >
                Cancel
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Modal>
  );
};

export const Vending = (props: any) => {
  const { act, data } = useBackend<VendingData>();

  return (
    <Window width={450} height={600} title={`Vending Machine - ${data.name}`}>
      <Window.Content>
        <Stack fill vertical>
          {(data.isCustom && <Stack.Item>{custom(data)}</Stack.Item>) || null}
          {(data.panel && (
            <Stack.Item>
              <Button
                fluid
                bold
                my={1}
                py={1}
                icon={data.speaker ? 'comment' : 'comment-slash'}
                content={`Speaker ${data.speaker ? 'Enabled' : 'Disabled'}`}
                textAlign="center"
                color={data.speaker ? 'green' : 'red'}
                onClick={() => act('togglevoice')}
              />
            </Stack.Item>
          )) ||
            null}
          {(data.advertisement && data.advertisement.length > 0 && (
            <Stack.Item>
              <Section>
                <BlockQuote>{data.advertisement}</BlockQuote>
              </Section>
            </Stack.Item>
          )) ||
            null}
          <Stack.Item grow>
            <Section scrollable fill title="Products">
              <Stack fill vertical>
                {data.products &&
                  data.products.map((value, i) => product(value))}
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
      {(data.needsPin && pinModal()) || null}
      {(data.isVending && !data.needsPin && pay(data.vendingData)) || null}
    </Window>
  );
};
