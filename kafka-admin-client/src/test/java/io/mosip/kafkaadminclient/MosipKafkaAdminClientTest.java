package io.mosip.kafkaadminclient;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ExecutionException;

import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.DescribeTopicsResult;
import org.apache.kafka.clients.admin.KafkaAdminClient;
import org.apache.kafka.clients.admin.ListTopicsResult;
import org.apache.kafka.clients.admin.TopicDescription;
import org.apache.kafka.common.KafkaFuture;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mockito;
import org.powermock.api.mockito.PowerMockito;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.powermock.modules.junit4.PowerMockRunner;

@RunWith(PowerMockRunner.class)
@PrepareForTest({ Admin.class })
public class MosipKafkaAdminClientTest {

    @SuppressWarnings("unchecked")
	@Test
	public void isTopicsPresentTest() throws Exception {
		PowerMockito.mockStatic(Admin.class);
		KafkaAdminClient adminMock = mock(KafkaAdminClient.class);
		PowerMockito.when(Admin.create(any(Properties.class))).thenReturn(adminMock);
    	ListTopicsResult listTopicsResult = Mockito.mock(ListTopicsResult.class);
		KafkaFuture<Set<String>> kafkaFuture = Mockito.mock(KafkaFuture.class);
		Set<String> sampleStrings = new HashSet<>();
		sampleStrings.add("test");
		Mockito.when(kafkaFuture.get()).thenReturn(sampleStrings);
		Mockito.when(listTopicsResult.names()).thenReturn(kafkaFuture);
		Mockito.when(adminMock.listTopics(Mockito.any())).thenReturn(listTopicsResult);
		MosipKafkaAdminClient mosipKafkaAdminClient = new MosipKafkaAdminClient("test");
		Assert.assertTrue(mosipKafkaAdminClient.isTopicsPresent("test"));
	} 
    
    @SuppressWarnings("unchecked")
	@Test
	public void createTopicsExceptionTest() throws InterruptedException, ExecutionException {
    	PowerMockito.mockStatic(Admin.class);
		KafkaAdminClient adminMock = mock(KafkaAdminClient.class);
		PowerMockito.when(Admin.create(any(Properties.class))).thenReturn(adminMock);
		CreateTopicsResult createTopicsResult = Mockito.mock(CreateTopicsResult.class);
		Map<String, KafkaFuture<Void>> testMap = new HashMap<>();
		KafkaFuture<Void> kafkaFuture = Mockito.mock(KafkaFuture.class);
		testMap.put("test-topic", kafkaFuture);
		Mockito.when(kafkaFuture.get()).thenThrow(ExecutionException.class);
		Mockito.when(createTopicsResult.values()).thenReturn(testMap);
		Mockito.when(adminMock.createTopics(Mockito.any())).thenReturn(createTopicsResult);
		MosipKafkaAdminClient mosipKafkaAdminClient = new MosipKafkaAdminClient("test-topic");
		Assert.assertThrows(ExecutionException.class, () -> mosipKafkaAdminClient.createTopic("test-topic"));
    }
    
    @SuppressWarnings("unchecked")
	@Test
	public void createTopicsTest() throws Exception {
    	PowerMockito.mockStatic(Admin.class);
		KafkaAdminClient adminMock = mock(KafkaAdminClient.class);
		PowerMockito.when(Admin.create(any(Properties.class))).thenReturn(adminMock);
		CreateTopicsResult createTopicsResult = Mockito.mock(CreateTopicsResult.class);
		Map<String, KafkaFuture<Void>> testMap = new HashMap<>();
		KafkaFuture<Void> kafkaFuture = Mockito.mock(KafkaFuture.class);
		testMap.put("test-topic", kafkaFuture);
		Mockito.when(kafkaFuture.get()).thenReturn(null);
		Assert.assertEquals(kafkaFuture.get(), null);
		Mockito.when(createTopicsResult.values()).thenReturn(testMap);
		Mockito.when(adminMock.createTopics(Mockito.any())).thenReturn(createTopicsResult);
		MosipKafkaAdminClient mosipKafkaAdminClient = new MosipKafkaAdminClient("test-topic");
		mosipKafkaAdminClient.createTopic("test-topic");
    }
    
    @SuppressWarnings("unchecked")
	@Test
	public void describeTopicTest() throws Exception {
    	PowerMockito.mockStatic(Admin.class);
		KafkaAdminClient adminMock = mock(KafkaAdminClient.class);
		PowerMockito.when(Admin.create(any(Properties.class))).thenReturn(adminMock);
		DescribeTopicsResult result = Mockito.mock(DescribeTopicsResult.class);
		KafkaFuture<Map<String, TopicDescription>> kafkaFutureVal = Mockito.mock(KafkaFuture.class);
		Map<String, TopicDescription> resultMap = new HashMap<>();
		Mockito.when(kafkaFutureVal.get()).thenReturn(resultMap);
		Mockito.when(result.all()).thenReturn(kafkaFutureVal);
		Mockito.when(adminMock.describeTopics(Mockito.anyCollection())).thenReturn(result);
		MosipKafkaAdminClient mosipKafkaAdminClient = new MosipKafkaAdminClient("test-topic");
		Assert.assertEquals(mosipKafkaAdminClient.describeTopic("test-topic"), resultMap);
    }

}