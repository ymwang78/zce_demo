--[[
new_threadpool ����һ���̳߳�
-- ����1���̳߳��ڵ��߳�����

new_service ����һ�������������������һ�����֣���ִ������ļ�
������lua�������Ҳ�������ִ������ļ����������Ĭ�ϵ����� "main"

ÿ���������״̬�����ģ�����Ĭ�����������������ִ���̳߳أ�
�����������ķ������˴���������API���ᵼ��ִ���̳߳ر����Ĺ⣬
���new_service�����û�ָ���÷���ʹ�ö������̳߳أ���ָ�������߳�����

һ�����ܵĳ�����
ͨ�����ֻ��ƺ�LPC������ƣ����Զ����ڵײ��ܶ�����LUA����ʵ�ֿ�������API��COROUTINEʵ�֡�
����������mongodb��ѯ��lua�⣬�����������ģ��ײ�����δ�ṩCOROUTINE֧�֡�
��ʱ��Ϳ���ʵ��һ��MONGODB�Ĳ�ѯ���񣬲�ָ���������̳߳ء�
ʹ����ʹ��LPC����ʵ��COROUTINE��ѯ���������߼�ģ���Ƿ������ġ�

����ע�⣬һ�������ֻ��ռ��һ���̣߳�������Ҫʵ�ֶ���߳���ͬһ��������Ҫ�Լ���װ��
����Բ�ͬ�����֣�����"svr0","svr1"����ε���new_service��
Ȼ�����з�װAPI��Ͷ��lpc������ø���ͬ��svr

-- ����1�� ����
-- ����2,  �ļ�
-- ����3�� �߳����ؾ������ѡ
--]]

local c = require "zce.core"

--[[
local t = require("tooyoung.tooyoung")
t.start()

local unitest = require("tooyoung.unittest")
unitest.test_me()

--]]
--[[
local t = require("diandian.diandian")
t.start()

local unitest = require("diandian.unittest")
unitest.test_me()
--]]

local unitest = require("test.test")
unitest.test_me()
